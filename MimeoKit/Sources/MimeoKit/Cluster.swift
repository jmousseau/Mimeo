//
//  KMeans.swift
//  MimeoKit
//
//  Created by Jack Mousseau on 10/7/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

// MARK: - Clusterable

/// A clusterable type.
public protocol Clusterable {

    /// The clusterable's cluster feature type.
    associatedtype ClusterFeature

    /// The clusterable's cluster features.
    func clusterFeatures() -> [ClusterFeature]

}

// MARK: - Distance Functions

/// A collection of distance functions.
public enum DistanceFunctions {

    /// The Euclidian distance function.
    public static let euclidian: ([Double], [Double]) -> Double = { lhs, rhs -> Double in
        sqrt(zip(lhs, rhs).reduce(0) { sumOfDifferencesSquared, pair -> Double in
            sumOfDifferencesSquared + pow(pair.1 - pair.0, 2)
        })
    }

}

// MARK: - Cluster

/// A cluster is a group of clusterable observations. Currently, the cluster
/// feature type must be a `Double`.
public final class Cluster<
    Observation: Clusterable
> where Observation.ClusterFeature == Double {

    /// A cluster feature vector is a collection of cluster features.
    public typealias FeatureVector = [Observation.ClusterFeature]

    /// A cluster centroid is simply a feature vector. By definition, its
    /// dimension must match that of the cluster's feature vectors.
    public typealias Centroid = FeatureVector

    /// A cluster result is a collection of clusters and the corresponding
    /// clustering error.
    public typealias Result = (clusters: [Cluster<Observation>], error: Double)

    /// A distance function computes the distance between two feature vectors.
    public typealias DistanceFunction = (FeatureVector, FeatureVector) -> Double

    /// A cluster method.
    public enum Method {

        /// The K-means clustering method.
        ///
        /// The error term is the sum of the distances squared where each
        /// distance is measured from the cluster's `centroid` to an observation
        /// using the `distanceFunction` provided.
        ///
        /// - Parameter numberOfGroups The number of clusters to create.
        /// - Parameter iterations The maximum number of iterations the
        ///   algorithm will attempt to converge the centroids. Defaults to 100.
        /// - Parameter distanceFunction The function used measure distances
        ///   between feature vectors. Defaults to the Eclidian distance
        ///   function.
        case kMeans(
            numberOfGroups: Int,
            iterations: Int = 100,
            distanceFunction: DistanceFunction = DistanceFunctions.euclidian
        )

        /// The K-means elbow clustering method.
        ///
        /// The "elbow method" runs K-means for many different values of K and
        /// determines the best K by looking at the slope of the error curve.
        ///
        /// The error term is the sum of the distances squared where each
        /// distance is measured from the cluster's `centroid` to an observation
        /// using the `distanceFunction` provided.
        ///
        /// - Parameter threshold: The required percentage change between
        ///   sequential K-means clustering attempts. If the percentage is less
        ///   than the threshold, K is chosen as the previously attempted
        ///   cluster count.
        /// - Parameter maximumNumberOfGroups: The maximum number of clusters
        ///   that may be created.
        /// - Parameter iterations: The maximum number of iterations the
        ///   algorithm will attempt to converge the centroids. Defaults to 100.
        /// - Parameter distanceFunction: The function used measure distances
        ///   between feature vectors. Defaults to the Eclidian distance
        ///   function.
        case kMeansElbow(
            threshold: Double,
            maximumNumberOfGroups: Int,
            iterations: Int = 100,
            distanceFunction: DistanceFunction = DistanceFunctions.euclidian
        )

    }

    /// A cluster error.
    public enum Error: Swift.Error {

        /// There were no observations provided to cluster.
        case noObservations

        /// Not all the observations provided had feature vectors with the same
        /// dimension.
        case dimensionMismatch

    }

    /// An internal wrapper of an original observation used to mutate the
    /// observation's feature vector.
    fileprivate final class InternalObservation {

        /// The internal observation's original observation passed to the
        /// `cluster(using:)` method.
        fileprivate let originalObservation: Observation

        /// The original observation's feature vector. Mutated by every
        /// clustering method.
        fileprivate var features: FeatureVector

        /// Initialize an internal observation.
        /// - Parameter observation: The internal observation's original
        /// observation.
        fileprivate init(observation: Observation) {
            self.originalObservation = observation
            self.features = observation.clusterFeatures()
        }

    }

    /// The cluster's feature dimension.
    public let featureDimension: Int

    /// The cluster's feature dimensions.
    fileprivate let featureDimensions: Range<Int>

    /// The cluster's observations.
    public fileprivate(set) var observations = [Observation]()

    /// The cluster's observations represented as internal observations. Heavily
    /// modified by the clustering algorithm and should never be returned to the
    /// `cluster(using:)` caller.
    fileprivate var internalObservations = [InternalObservation]()

    /// The cluster's centroid.
    public private(set) var centroid = Centroid()

    /// Initialize a cluster.
    /// - Parameter observations: The cluster's observations.
    public init(observations: [Observation]) throws {
        guard let firstObservation = observations.first else {
            throw Error.noObservations
        }

        self.featureDimension = firstObservation.clusterFeatures().count
        self.featureDimensions = 0..<featureDimension
        self.observations = observations
        self.internalObservations = observations.map(InternalObservation.init)
    }

    /// Initialize a cluster.
    /// - Parameter featureDimension: The cluster's feature dimensino
    /// - Parameter centroid: The cluster's centroid.
    fileprivate init(featureDimension: Int, centroid: Centroid) {
        self.featureDimension = featureDimension
        self.featureDimensions = 0..<featureDimension
        self.centroid = centroid
    }

    /// Cluster the cluster using the method provided.
    /// - Parameter clusterMethod: The desired clustering method.
    public func cluster(using clusterMethod: Method) -> Result {
        switch clusterMethod {
        case .kMeans(let numberOfGroups, let iterations, let distanceFunction):
            return clusterUsingKMeans(
                numberOfGroups: numberOfGroups,
                iterations: iterations,
                distanceFunction: distanceFunction
            )

        case .kMeansElbow(
            let threshold,
            let maximumNumberOfGroups,
            let iterations,
            let distanceFunction
        ):
            return clusterUsingKMeansElbow(
                threshold: threshold,
                maximumNumberOfGroups: maximumNumberOfGroups,
                iterations: iterations,
                distanceFunction: distanceFunction
            )
        }
    }

}

// MARK: - K Means`

extension Cluster {

    /// Cluster using K-means.
    /// - Parameter numberOfGroups: The number of clusters to create.
    /// - Parameter iterations: The maximum number of iterations the algorithm
    ///   will attempt to converge the centroids. Defaults to 100.
    /// - Parameter distanceFunction: The function used measure distances
    ///   between feature vectors. Defaults to the Eclidian distance function.
    fileprivate func clusterUsingKMeans(
        numberOfGroups: Int,
        iterations: Int,
        distanceFunction: DistanceFunction
    ) -> Result {
        var clusters = [Cluster]()

        for _ in 0..<numberOfGroups {
            clusters.append(Cluster(
                featureDimension: featureDimension,
                centroid: randomCentroid()
            ))
        }

        for _ in 0..<iterations {
            clusters.forEach({ (cluster: Cluster) in
                cluster.internalObservations.removeAll()
                cluster.observations.removeAll()
            })

            assignObservations(to: clusters, using: distanceFunction)
            let previousCentroids = centroids(for: clusters)
            assignCentroids(to: clusters)

            if previousCentroids == centroids(for: clusters) {
                break
            }
        }

        return (clusters, clusters.reduce(0, { sumOfSumOfSquares, cluster -> Double in
            sumOfSumOfSquares + cluster.observations.reduce(0, { sumOfDistances, observation -> Double in
                sumOfDistances + distanceFunction(cluster.centroid, observation.clusterFeatures())
            })
        }))
    }

    /// Returns a feature slice across all observations at a particular
    /// dimension.
    /// - Parameter featureDimension: The feature dimension at which to create
    ///   the feature slice.
    private func featureSlice(at featureDimension: Int) -> FeatureVector {
        internalObservations.map({ observation in
            observation.features[featureDimension]
        })
    }

    /// Returns a random centroid such that each element of the centroid is
    /// within the minimum and maximum of its corresponding feature slice.
    private func randomCentroid() -> Centroid {
        featureDimensions.map({ featureDimension in
            let values = featureSlice(at: featureDimension)
            return Double.random(in: values.min()!...values.max()!)
        })
    }

    /// Returns the centroids for a collection of cluster.
    /// - Parameter clusters: The centroids corresponding to the specified
    ///   clusters.
    private func centroids(for clusters: [Cluster]) -> [Centroid] {
        clusters.map({ cluster in
            cluster.centroid
        })
    }

    /// Assign observations to the closest cluster.
    /// - Parameter clusters: The current clusters.
    /// - Parameter distanceFunction: The distance function used to measure the
    ///   distance between each cluster's centroid and all observations.
    private func assignObservations(
        to clusters: [Cluster],
        using distanceFunction: DistanceFunction
    ) {
        for observation in internalObservations {
            let centroids = self.centroids(for: clusters)

            var shortestDistance = Double.greatestFiniteMagnitude
            var closestCluster = clusters.first!

            for (index, centroid) in centroids.enumerated() {
                let distance = distanceFunction(centroid, observation.features)
                if distance < shortestDistance {
                    shortestDistance = distance
                    closestCluster = clusters[index]
                }
            }

            closestCluster.internalObservations.append(observation)
            closestCluster.observations.append(observation.originalObservation)
        }
    }

    /// Assign centroids to the clusters provided by taking the mean of the
    /// feature vectors at the appropriate dimension.
    /// - Parameter clusters: The clusters for which to assign new centroids.
    private func assignCentroids(to clusters: [Cluster]) {
        for cluster in clusters {
            var means = [Observation.ClusterFeature]()

            for featureDimension in featureDimensions {
                let features = cluster.internalObservations.map({ observation in
                    observation.features[featureDimension]
                })

                means.append(features.count > 0 ? features.mean() : 0)
            }

            cluster.centroid = means
        }
    }

}

// MARK: - K Means Elbow

extension  Cluster {

    /// Cluster using the K-Means with the elbow method.
    /// - Parameter threshold: The required percentage change between sequential
    ///   K-means clustering attempts. If the percentage is less than the
    ///   threshold, K is chosen as the previously attempted cluster count.
    /// - Parameter maximumNumberOfGroups: The maximum number of clusters that
    ///   may be created.
    /// - Parameter iterations: The maximum number of iterations the
    ///   algorithm will attempt to converge the centroids. Defaults to 100.
    /// - Parameter distanceFunction: The function used measure distances
    ///   between feature vectors. Defaults to the Eclidian distance function.
    fileprivate func clusterUsingKMeansElbow(
        threshold: Double,
        maximumNumberOfGroups: Int,
        iterations: Int,
        distanceFunction: DistanceFunction
    ) -> Result {
        var clusters = [Cluster]()
        var previousError = 0.0

        for numberOfGroups in 1...min(maximumNumberOfGroups, observations.count) {
            let result = clusterUsingKMeans(
                numberOfGroups: numberOfGroups,
                iterations: iterations,
                distanceFunction: distanceFunction
            )

            if (result.clusters.reduce(false, { containsEmptyCluster, cluster in
                return containsEmptyCluster || cluster.observations.isEmpty
            })) {
                return (clusters, previousError)
            }

            if ((abs(result.error - previousError) / previousError) < threshold) {
                return (clusters, previousError)
            }

            clusters = result.clusters
            previousError = result.error
        }

        return (clusters, previousError)
    }

}
