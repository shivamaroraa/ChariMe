import 'dart:math';

import 'package:ChariMe/enums/aws_regions.dart';
import 'package:ChariMe/models/npoModel.dart';
import 'package:ChariMe/models/userModel.dart';
import 'package:ChariMe/utilities/index.dart';
import 'package:aws_s3_client/aws_s3_client.dart';
import 'package:mysql1/mysql1.dart';

/*
Uploads an image to the S3 bucket and links the file with the
associated table entry in the database.

image: the image being uploaded.
id: the identifying column entry for the table: e.g. username for users/non_profit,
    and title for campaigns.
tableName: the table that should be updated.


See lib/screens/portrait/campaigns/addNewCampaignPortrait.dart for example
*/
Future<String> uploadImage(File image, String id, String tableName,
    {isBanner = false}) async {
  var aws_path = 'https://db-images-link.s3.us-east-2.amazonaws.com/';
  String image_path = '';

  // Uploads the image to the S3 bucket and gets the associated image path
  try {
    Spaces spaces = Spaces(
      region: "us-east-2",
      accessKey: 'AKIA3CR2WLZR33PXWCNL',
      secretKey: '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',
    );

    Bucket bucket = spaces.bucket('db-images-link');
    String res = await bucket.uploadFile(
        image.path, image.readAsBytesSync(), 'image', Permissions.public);
    image_path = '$aws_path${image.path}';
  } catch (e) {
    print("ERROR IS THIS: $e");
  }

  // Updates the associated database entry with the S3 bucket link
  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  // just in case of an accident
  if (tableName.toLowerCase() == 'users') isBanner = false;
  String idType;
  String colType;
  if (tableName.toLowerCase() == 'non_profit')
    idType = 'username';
  else
    idType = (tableName.toLowerCase() == 'campaigns') ? 'title' : 'username';

  colType = (isBanner || tableName.toLowerCase() == 'campaigns')
      ? 'bannerImage'
      : 'profilePicture';

  String query =
      'update $tableName set $colType = "$image_path" where $idType = "$id"';
  var result = await conn.query(query);

  conn.close();

  return image_path;
}

Future<List<Campaigns>> getAllCampaigns() async {
  Map<String, Campaigns> mapCampaigns = {};
  List<Campaigns> allCampaigns = [];

  print("started");

  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  try {
    print("Trying to fetch data.");
    var results = await conn.query('select * from campaigns LIMIT 50');
    String profilePic;
    for (var row in results) {
      var campSum = await conn.query(
          'select sum(amount) from donations where campaignID =?', [row[0]]);
      double sum = 0;
      for (var s in campSum) {
        sum = s[0];
      }

      var resSet = await conn.query(
          ('select profilePicture from non_profit where username = "${row[4]}"'));
      for (var s in resSet) {
        profilePic = s[0].toString();
      }
      var campDictionary = Campaigns(
          campTitle: '${row[1]}' ?? '',
          campDescription: '${row[2]}' ?? '',
          isActive: row[3] == 1 ? true : false,
          hostedByNPO: '${row[4]}' ?? '',
          bannerImage: '${row[5] ?? ''}',
          totalMoneyRaised: sum.runtimeType == Null ? 0.0 : sum,
          npoProfile: profilePic);
      mapCampaigns['${row[1]}'] = campDictionary;
    }
    mapCampaigns.forEach((key, value) {
      allCampaigns.add(value);
    });
  } catch (e) {
    print(e);
  }

//  for (var camps in allCampaigns){
//    print(camps.hostedByNPO + ': '+ '${camps.totalMoneyRaised}');
//  }

  conn.close();
  return allCampaigns;
}

Future<User> getUserInfo(String username) async {
  User loggedInUser;

  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  try {
    print("Trying to fetch data for the user information.");
    var results =
        await conn.query('select * from users where username = ?', [username]);
    for (var row in results) {
      loggedInUser = User(
        username: username ?? '',
        fullName: '${row[1]}' ?? '',
      );
    }
    var donations = await conn.query(
        'SELECT SUM(amount) FROM donations WHERE username = ?', [username]);
    for (var row in donations) {
      loggedInUser.totalDonated = row[0].runtimeType == Null ? 0 : row[0];
    }
  } catch (e) {
    print(e);
  }

  conn.close();
  return loggedInUser;
}

Future<NPO> getNpoDetails(String name) async {
  print("NPO started");
  NPO loggedInNpo;

  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  try {
    print("Trying to fetch data for the NPO information.");
    var results =
        await conn.query('select * from non_profit where username = ?', [name]);
    for (var row in results) {
      loggedInNpo = NPO(
        username: '${row[0]}' ?? '',
        name: name ?? '',
        region: '${row[2]}' ?? '',
        npoDescription: '${row[3]}',
        profilePicture: '${row[5]}' ?? '',
        bannerPicture: '${row[6]}' ?? '',
      );
    }
    var donations = await conn.query(
        'select sum(donations.amount) from donations, campaigns where donations.campaignID = campaigns.campaignID and campaigns.name = ?',
        [name]);
    for (var row in donations) {
      loggedInNpo.totalMoneyRaised = row[0] ?? 0;
    }

    var activeCamps = await conn.query(
        'select count(campaignID) from campaigns where campaigns.isActive = 1 and campaigns.name = ?',
        [name]);
    for (var row in activeCamps) {
//      print(row[0]);
      loggedInNpo.numActiveCampaigns = row[0] ?? 0;
    }

    var inactiveCamps = await conn.query(
        'select count(campaignID) from campaigns where campaigns.isActive = 0 and campaigns.name = ?',
        [name]);
    for (var row in inactiveCamps) {
      loggedInNpo.numInactiveCampaigns = row[0] ?? 0;
    }
  } catch (e) {
    print(e);
  }

  conn.close();
  print("info gathered: " +
      loggedInNpo.username +
      " " +
      loggedInNpo.region +
      " " +
      loggedInNpo.name);
//  print(loggedInNpo.totalMoneyRaised);
//  print((loggedInNpo.numActiveCampaigns));
//  print((loggedInNpo.numInactiveCampaigns));
  return loggedInNpo;
}

Future<NPO> getNpoInfo(String username) async {
  print("NPO started");
  NPO loggedInNpo;

  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  try {
    print("Trying to fetch data for the NPO information.");
    var results = await conn
        .query('select * from non_profit where username = ?', [username]);
    for (var row in results) {
      loggedInNpo = NPO(
          username: username ?? '',
          name: '${row[1]}' ?? '',
          region: '${row[2]}' ?? '',
          npoDescription: '${row[3]}');
    }
    var donations = await conn.query(
        'select sum(donations.amount) from donations, campaigns where donations.campaignID = campaigns.campaignID and campaigns.username = ?',
        [username]);
    for (var row in donations) {
      loggedInNpo.totalMoneyRaised = row[0] ?? 0;
    }

    var activeCamps = await conn.query(
        'select count(campaignID) from campaigns where campaigns.isActive = 1 and campaigns.username = ?',
        [username]);
    for (var row in activeCamps) {
//      print(row[0]);
      loggedInNpo.numActiveCampaigns = row[0] ?? 0;
    }

    var inactiveCamps = await conn.query(
        'select count(campaignID) from campaigns where campaigns.isActive = 0 and campaigns.username = ?',
        [username]);
    for (var row in inactiveCamps) {
      loggedInNpo.numInactiveCampaigns = row[0] ?? 0;
    }
  } catch (e) {
    print(e);
  }

  conn.close();
  print("info gathered: " +
      loggedInNpo.username +
      " " +
      loggedInNpo.region +
      " " +
      loggedInNpo.name);
//  print(loggedInNpo.totalMoneyRaised);
//  print((loggedInNpo.numActiveCampaigns));
//  print((loggedInNpo.numInactiveCampaigns));
  return loggedInNpo;
}

Future<List<NPO>> getAllNPO() async {
  List<NPO> allNPOs = [];
  print("NPO started");

  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  try {
    var results = await conn.query('select * from non_profit LIMIT 50');
    for (var row in results) {
      var npo = NPO(
        username: '${row[0]}' ?? '',
        name: '${row[1]}' ?? '',
        region: '${row[2]}' ?? '',
        npoDescription: '${row[3]}' ?? '',
        totalMoneyRaised: 0.0,
        profilePicture: '${row[5]}' ?? '',
        bannerPicture: '${row[6]}' ?? '',
      );
      allNPOs.add(npo);
    }
  } catch (e) {
    print(e);
  }

  conn.close();
  return allNPOs;
}

Future<String> getTotalRaisedByTheApp() async {
  String total;

  var settings = new ConnectionSettings(
      host: 'app-db.cdslhq2tdh2f.us-east-2.rds.amazonaws.com',
      port: 3306,
      user: 'peanut',
      password: 'willywonka',
      db: 'data');
  var conn = await MySqlConnection.connect(settings);

  try {
    var results = await conn.query('select sum(amount) from donations');
    for (var row in results) {
      total = '${row[0]}';
    }
  } catch (e) {
    print(e);
  }

  print(total);

  conn.close();
  return total;
}
