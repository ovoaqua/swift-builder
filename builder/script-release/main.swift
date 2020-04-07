#!/usr/bin/env swiftshell
//  main.swift
//  swift-release
//
//  Created by Christina S on 2/3/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import SwiftShell


// TODO: Create addt'l script that will run all unit tests (started, need to finish)
// TODO: Prompt to push branch
// TODO: If they want to push, prompt to create PR
// TODO: Create PR w/github api
// TODO: Include sample apps scripts to update podfile version


var version: String? = nil
var newModuleName: String? = nil
var versionExists = false
var cleanctx = CustomContext(main)
var result = cleanctx.run(bash: "brew install xcodegen")
var publicRepoPath: String?
var builderRepoPath: String?
var greeting: String {
    result = cleanctx.run(bash: "brew install python3")
    return """
    ************************* Tealium Builder Release Script ************************\n
    *********************************************************************************
             👩🏻‍💻 Make sure you do not have the tealium-swift project open! 👨‍💻
    \n
    """
}

func getRepoPaths() {
    print("What is the full path to your builder repo?")
    while let path = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        builderRepoPath = path
        break
    }
    print("What is the full path to your public repo?")
    while let path = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        publicRepoPath = path
        break
    }
}

func greetAndSetDirectories() {
    print(greeting)
    cleanctx.env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    cleanctx.currentdirectory = publicRepoPath ?? ""
}


func checkVersion() {
    print("Please provide a version number to release: ")
    while let input = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        result = cleanctx.run(bash: "git branch")
        version = input
        if result.stdout.contains(input) {
            print("Version already exists, skipping version update")
            // skip until checking `nothing to commit step`
            versionExists = true
            break
        }
        print("updating to version number \(version!)")
        break
    }
}

func checkForNewModules(_ version: String) {
    cleanctx.currentdirectory = builderRepoPath ?? ""
    print("Do you need to add any new modules in this version? y/n")
    while let input = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        if input.lowercased() == "y" {
            print("Please enter the module name (format = TealiumNewModule): ")
            newModuleName = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters)

            let shortModuleName = newModuleName?.replacingOccurrences(of: "Tealium", with: "").lowercased()
            print("Do you want to exclude any platforms from this module? y/n")
            while let shouldExclude = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
                if shouldExclude == "y" {
                    print("List your excluded platforms in a comma separated string e.g. tvos,osx")
                    while let excluded = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
                        result = cleanctx.run(bash: "python3 ./new-module.py -v \(version) -f \(newModuleName!) -s \(shortModuleName!) -e \(excluded)")
                        break
                    }
                } else {
                    cleanctx.run(bash: "python3 ./new-module.py -v \(version) -f \(newModuleName!) -s \(shortModuleName!)")
                }
                break
            }
        } else {
            cleanctx.run(bash: "python3 ./new-module.py -v \(version)")
        }
        break
    }
}

func checkForChanges() {
    cleanctx.run(bash: "git fetch")
    result = cleanctx.run(bash: "git status")
    if !result.stdout.contains("nothing to commit") {
        print("There are unstaged changes, please commit or stash")
        // provide options - 1 to stash 2
        print("1 - stash changes")
        print("2 - commit changes")
        while let input = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
            if input == "1" {
                cleanctx.run(bash: "git stash save -u saved-by-swift-release-script-\(Date())")
                cleanctx.run(bash: "git clean -d -f")
                break
            } else if input == "2" {
                print("Enter commit msg: ")
                while let commitMsg = main.stdin.readSome() {
                    cleanctx.run(bash: "git add --all")
                    cleanctx.run(bash: "git commit -m \(commitMsg)")
                    break
                }
                break
            }
        }
    }
}

func checkIfBranchAlreadyExists(_ version: String) {
    cleanctx.currentdirectory = publicRepoPath ?? ""
    if versionExists {
        cleanctx.run(bash: "git checkout \(version)")
    } else {
        cleanctx.run(bash: "git checkout -b \(version)")
    }

}

func copyPodspec(_ version: String) {
    // Copy podspec over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/tealium-swift.podspec ./")
    print("podspec copied")
}

func copyPackage() {
    // Copy Package.swift over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/Package.swift ./")
    print("Package.swift copied")
}

func swiftFormat() {
    // Format .swift files in builder repo
    cleanctx.currentdirectory = builderRepoPath ?? ""
    cleanctx.run(bash: "brew install swiftlint")
    cleanctx.run(bash: "swiftlint autocorrect --format --path tealium/")
    cleanctx.run(bash: "swiftlint autocorrect --format --path support/")
}

func copySourceFiles() {
    // Copy tealium folder over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/tealium ./")
    print("Tealium folder copied")
    
    // Copy unit tests folder over to public repo
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "rsync -arv \(builderRepoPath ?? "")/support ./")
    print("Support (unit tests) folder copied")
}

func runTests() {
    cleanctx.currentdirectory = "\(builderRepoPath ?? "")/builder"
    //cleanctx.run(bash: "chmod +x unit-tests.sh")
    //let _ = cleanctx.runAsync(bash: "./unit-tests.sh > ~/Desktop/testoutput.txt").onCompletion { command in
    cleanctx.run(bash: "chmod +x test.sh")
    let tests = cleanctx.runAsync(bash: "./test.sh > ~/Desktop/testoutput.txt").onCompletion { command in
        print("🤯complete")
        if let readfile = try? open("~/Desktop/testoutput.txt") {
            let contents = readfile.read()
            let numberOfFailures = contents.components(separatedBy: "failed")
            print("There were \(numberOfFailures.count - 1) failures in the unit tests. Please fix the failing tests and/or update the code, then come back and try again 😁")
        }
    }
    try? tests.finish()
}

func generateNewProject() {
    cleanctx.currentdirectory = publicRepoPath ?? ""
    cleanctx.run(bash: "cp \(builderRepoPath ?? "")/project.yml ./")
    result = cleanctx.run(bash: "xcodegen generate -p ./builder")
    cleanctx.run(bash: "rm ./project.yml")
    print("New project generated")
}


func removeUneccessaryFiles() {
    cleanctx.run(bash: "rm -rf ./builder/TealiumCrash && rm -rf ./builder/TealiumSwift && rm -rf ./builder/docs && rm ./builder/README.md")
    print("Extra folders/files removed")
}

func checkForNewTargets() {
    print("Do you need to add any new targets to the podfile and Package.swift?")
    while let newTargets = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
        if newTargets.lowercased() == "y" {
            // TODO: change the podspec and script for them
            print("Please manually update the tealium-swift.podspec and Package.swift by adding your new targets, then rerun the script")
            exit(0)
        }
        break
    }
}

func commitAndPushToBuilder(_ version: String) {
    // Committing version (podspec), module (package.swift), and formatting (swiftlint) changes to builder
    cleanctx.currentdirectory = builderRepoPath ?? ""
    cleanctx.run(bash: "git checkout -b release-script/\(version)-cleanup")
    cleanctx.run(bash: "git add --all")
    cleanctx.run(bash: "git commit -m \"Updated .podspec (possibly Package.swift) and formatteed using swfitlint for version \(version)\"")
    cleanctx.run(bash: "git push branch release-script/\(version)-cleanup")
    // submit pr
}

func commitAndPush(_ version: String) {
    cleanctx.run(bash: "git add --all")
    print("Added changes")
    cleanctx.run(bash: "git commit -m \(version)")
    print("Committed new version")
//    print("Which remote would you like to push to? e.g. origin")
//    while let remote = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
//        cleanctx.run(bash: "git push \(remote) \(version)")
//        break
//    }
//    print("Would you like to create a PR? y/n")
//    while let pr = main.stdin.readSome()?.trimmingCharacters(in: .controlCharacters) {
//        if pr == "y" {
//
//        }
//        break
//    }
    print("""
            🎉🎉 All Done! Once your PR is merged on both the builder and public repos, don't forget to do the following:
            1. Create a Release on GitHub
            2. Push to Cocoapods
            3. Update documentation/release notes
            4. Announce the new release in #support_mobile (slack)
          """)
    
    // git push
    // use github api to create PR
    // Remind them to publish release/tag on github <--script using github api // https://github.community/t5/How-to-use-Git-and-GitHub/How-to-create-full-release-from-command-line-not-just-a-tag/td-p/6895
    // look in .ssh config for .pub (prompt for name)
    // Push to cocoapods
    // Have you updated the documentation, including release notes
    // Announce in support mobile with documentation links - slack api? (send event to AS?)

}


//runTests()
getRepoPaths()
guard let _ = builderRepoPath,
    let _ = publicRepoPath else {
    print("You must enter the full paths to both the public and builder repos. Try again, please.")
    exit(1)
}
greetAndSetDirectories()
checkVersion()
checkForChanges()
guard let version = version else {
    print("You must enter a versoin number. Try again, please.")
    exit(1)
}
checkIfBranchAlreadyExists(version)
swiftFormat()
copySourceFiles()
checkForNewModules(version)
copyPackage()
copyPodspec(version)
commitAndPushToBuilder(version)
generateNewProject()
removeUneccessaryFiles()
commitAndPush(version)
// git push
// submit PR
// Remind them to publish release/tag on github <--script using github api // https://github.community/t5/How-to-use-Git-and-GitHub/How-to-create-full-release-from-command-line-not-just-a-tag/td-p/6895
// look in .ssh config for .pub (prompt for name)

RunLoop.main.run()
