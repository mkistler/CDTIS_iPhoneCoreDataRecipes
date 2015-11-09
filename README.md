# CDTIS_iPhoneCoreDataRecipes

This project demonstrates how to convert a
CoreData application to use [CDTIncrementalStore][cdtis].
We use [Apple's iPhoneCoreDataRecipes][recipe] sample application.  The
original code for the sample is the initial `git` checkin and
can also be found in branch [apple/original](a66fba04d038469).
You can read the original [ReadMe.txt](ReadMe.txt).

[cdtis]: https://github.com/jimix/CDTIncrementalStore "CDTIncrementalStore"
[recipe]: https://developer.apple.com/library/ios/samplecode/iPhoneCoreDataRecipes/Introduction/Intro.html "iPhoneCoreDataRecipes"

# Getting Started

This project depends on [CocoaPods][cocoapods], which is a dependency manager for Objective-C
that automates and simplifies the process of using 3rd-party libraries.
You should install CocoaPods using the [guide on their site][cpinstall].

Once CocoaPods is installed, you can install all the required dependencies (pods)
with the command

```bash
$ pod install
```

This creates a workspace directory `Recipe.xcworkspace` that you can
use to start Xcode. From now on, be sure to always open the generated
Xcode workspace instead of the project file when building your
project:

```bash
$ open Recipe.xcworkspace
```

[cocoapods]: http://cocoapods.org "CocoaPods"
[cpinstall]: http://guides.cocoapods.org/using/getting-started.html

# Summary of changes

The git log shows all changes made to convert the original sample app using CoreData
to use CDTIncrementalStore and sync with a remote Cloudant datastore.
You can see all the changes by diffing against `apple/original`.

### Consolidate recipes in a single persistent store

The original Recipes app created two separate SQLite DBs, one of which was pre-populated with the sample recipes and the other seemingly intended to hold user recipes.
However, the user recipes DB was never actually used -- new recipes were stored into the same DB as the sample recipes.
Moreover, the Recipes data model is not amenable to the use of multiple persistent stores since CoreData does not support cross-store relationships.
For these reasons, we removed the code to create the user DB and return a persistentStoreCoodinator for just the pre-populated datastore.

### Convert from sqlite to CDTIncrementalStore data store

Next, the app is changed to use CDTIncrementalStore instead of sqlite.
The CDTIncrementalStore package and its dependencies are integrated with the app
using CocoaPods.
From this point on we must use the Recipes.xcworkspace to build and run the app.
Once the dependencies are integrated, the only change required in the app is to
change the store type for the user store from `NSSQLiteStoreType` to
`[CDTIncrementalStore type]`.

### Simple refresh control on Recipes TVC

This change adds a refresh control to the Recipes TableViewController.
This is preparing for the next update, which will use the refresh to drive a synchronization with a remote Cloudant datastore.
