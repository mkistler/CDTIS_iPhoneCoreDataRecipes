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

# The Remote Data Store

To enable synchronization with a remote database in Cloudant,
we must create the database and set up access credentials and then
store these into our Recipes app.
To simplify the example, we will store the credentials as hard-coded
values in the application.
In a real application, the credentials might be entered by the user or
obtained from an application backend running in the cloud.

### Creating a New Database

You can sign up for a [Cloudant] account at their site. Once you have
registered and have launched into the dashboard, you will be given the
opportunity to add a new database.
Once you are at the dashboard, you can:

1. Select the `Databases` tab on the left
2. Select `Add New Database`
3. Call the new Database `recipes` (Note: Cloudant does not permit uppercase characters in the dbname)
4. Click `Create`

### Generate an API key

Now that the Database is created you can create an API key for the
application:

1. Click `Permissions`
2. Click `Generate API key`

You will be granted a `Key` and a `Password`, you should record these
and then give that `Key` permissions as `Reader`, `Writer` and
`Replicator`.

> ***Note***: When you navigate away from this page, there will be no
> way to retrieve the password for this key. If you forget it, you can
> simply generate a new pair and remove the old one.

[cloudant]: https://cloudant.com/

### Store the credentials in the app

To store the credentials in the app, open `ReplOperations.m` and locate the getter for `remoteURL`.
Here there are four NSString values that you must set with your Cloudant account and API key information obtained above.

```objc
		NSString *hostname = @"yourcloudantid.cloudant.com";
		NSString *dbname = @"recipes";
		NSString *key = @"APIKEY";
		NSString *password = @"APIPASSWORD";
```
Then uncomment this block of code so that the getter will return a valid
remoteURL.

# Running the app

Now you are ready to run the app and synchronize the locally stored recipes to your remote Cloudant database.
The local database will be populated with the initial set of recipes.
You can add recipes to this if you choose.
Pulling down on the tableview will kick off a refresh operation which will
replicate the local db contents into the Cloudant database you created above.

After replicating, you should be able to see your recipes in the remote database using the Cloudant dashboard.
Just open the recipes database and you should see a set of documents.
If you did not add any recipes before replicating, the remote database
should contain 51 documents.

# Accessing recipes from multiple devices

With the recipes stored in the remote Cloudant database, you can now access
these recipes -- both read and update -- from multiple devices.
Changes made on one device can be synchronized with the remote DB,
and will then be shown on other devices the next time the device does
a pull or sync with the remote DB.

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

### Refresh performs sync with remote DB

This change fills out the refresh control to perform a sync with a remote database in Cloudant.
The location and credentials for the remote DB are stored in the app
as described above.
The sync is performed with a pull replication followed by a push replication.
These are implemented in NSOperations to make it easy to schedule and chain them.
After the DB operations finish, a final operation is run to bring the data in the view controller up-to-date.

### Only load samples if remote DB is empty

To complete the conversion of the app to a true cloud-based recipe store,
the app must first load the receipes from the remote DB and only
when finding that empty should it load the sample recipes into the DB.
This avoids placing multiple copies of the sample recipes in the DB when
the app is used on multiple devices.
