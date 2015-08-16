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
to use CDTIncrementalStore and sync with a remote cloudant datastore.
You can see all the changes by diffing against `apple/original`.

### Convert user store from sqlite to CDTIncrementalStore

The first change to the sample application was to convert the UserRecipes store
to use CDTIncrementalStore instead of sqlite.
The CDTIncrementalStore package and its dependencies are integrated with the app
using CocoaPods.
From this point on we must use the Recipes.xcworkspace to build and run the app.

Next we need to change the CoreData initialization code in `RecipesAppDelegate.m`.
Here we changed the user store name to use the `.cdtis` suffix to signify that it is
a CDTIncrementalStore and we changed the store type from `NSSQLiteStoreType` to `[CDTIncrementalStore type]`.
Note that we leave the default store as a sqlite store, so the application is using both a sqlite store and CDTIncrementalStore.
We also changed the default store to be read-only, so all new recipes go to the user store.

