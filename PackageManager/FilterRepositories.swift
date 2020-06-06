//
//  FilterRepositories.swift
//  PackageManager
//
//  Created by Peter Schorn on 6/2/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation



struct FilterResult: Hashable, Equatable {
    
    let url: String
    let name: String?
    let attributeRanges: [Range<String.Index>]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.url == rhs.url
    }

}

extension GlobalEnv {
    
    func filterRepos() -> [FilterResult] {
        let search = searchText.strip()
        
        // exit early if the search or saved repos are empty
        if search.isEmpty || saved_repos.isEmpty {
            return saved_repos.map { repo in
                FilterResult(
                    url: repo.url,
                    name: repo.name,
                    attributeRanges: []
                )
            }
        }

        // analyze each repositories for the search text
        var ratedResults: [(FilterResult, rating: Double)] = []
        for repo in saved_repos {


            /// Indicates how well the repo matched the search query.
            var rating = 0.0
            /// The ranges of the repo url that should be highlighted
            /// because they matched part of the search query.
            var attributeRanges: [Range<String.Index>] = []
            
            var searchItems: [String] = []
            searchItems.append(search)
            searchItems.append(contentsOf: search.words())
            
            
            // iterate through each of the search items and look for
            // matches in the repo url and repo name
            for (i, searchItem) in searchItems.enumerated() {
                
                // if the search word was matched in repo url
                for (j, repoInfo) in [repo.url, repo.name].removeIfNil().enumerated() {
                    if let matches = try! repoInfo.regexFindAll(searchItem, searchRegexOptions) {
                        
                        // increment the rating by the number of times the search
                        // word was found in the repo url
                        rating += Double(matches.count)
                        
                        // if the entire search term was matched
                        if i == 0 {
                            rating *= 1.2
                        }
                        
                        // only append the range of the match for the url,
                        // because the name is not visible in the list
                        if j == 1 { continue }
                        
                        for match in matches {
                            
                            // append the range of the matched
                            // search word in the url, so it can be
                            // highlighted in the list
                            attributeRanges.append(match.range)
                            
                        }
                        
                    }
                    
                }
                
            }
                    
            if rating == 0 { continue }
            // let strRating = " (\(rating.format(.stripTrailingZeros)))"

            ratedResults.append((
                FilterResult(
                    url: repo.url,
                    name: repo.name,
                    attributeRanges: attributeRanges
                ),
                rating: rating
            ))
                    
        }  // end for repo in saved_repos
        
        // sort the results by rating
        ratedResults.sort(by: { $0.rating > $1.rating })

        // return an array of the filter results, excluding the ratings.
        return ratedResults.map { $0.0 }
        
    }


}
