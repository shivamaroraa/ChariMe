import 'package:ChariMe/models/npoModel.dart';
import 'package:ChariMe/utilities/index.dart';

class CharityScreenPortrait extends StatefulWidget {
  final String charityBanner;
  final String charityImage;
  final String charityName;
  final double moneyRaised;
  final String desc;

  CharityScreenPortrait(
      {this.charityBanner,
      this.charityName,
      this.charityImage,
      this.moneyRaised,
      this.desc});

  @override
  _CharityScreenPortraitState createState() => _CharityScreenPortraitState();
}

class _CharityScreenPortraitState extends State<CharityScreenPortrait> {
  Widget build(BuildContext context) {
    List<Campaigns> campaigns = Provider.of<List<Campaigns>>(context);
    List<NPO> npo = Provider.of<List<NPO>>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          Container(
            height: screenHeight(context) * 0.4,
            child: Stack(
              children: [
                Stack(
                  children: [
                    Image.network(
                      widget.charityBanner,
                      fit: BoxFit.fill,
                      height: screenHeight(context) * 0.32,
                      width: screenWidth(context),
                    ),
                    Positioned(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(FontAwesomeIcons.chevronLeft),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 180,
                      left: 125,
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 100,
                          width: 100,
                          child: Card(
                            elevation: 2,
                            shape: CircleBorder(),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).buttonColor,
                              backgroundImage:
                                  NetworkImage(widget.charityImage),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                sizedBox(20, 0),
              ],
            ),
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Text(
                  widget.charityName,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              sizedBox(10, 0),
              Text(
                'Total Money Raised',
                style: TextStyle(
                  fontSize: 23,
                ),
              ),
              sizedBox(10, 0),
              Text(
                '\$1204055',
                style: TextStyle(
                  fontSize: 23,
                  color: Theme.of(context).accentColor,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: ListView(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    getCharityDetailsCard(
                        context, 'Successful Campaigns', '30'),
                    getCharityDetailsCard(context, 'Current Campaigns', '15'),
                  ],
                ),
                sizedBox(10, 0),
                getHomeHeader(
                  context,
                  'About',
                  'Get to know more about ${widget.charityName}',
                ),
                sizedBox(10, 0),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getRichText(context, 'Country of Origin: ', 'USA'),
                        getRichText(context, 'Founded: ', '1985'),
                      ],
                    ),
                  ],
                ),
                sizedBox(10, 0),
                Text(widget.desc),
                sizedBox(10, 0),
                getHomeHeader(context, 'Current Campaigns',
                    'Campaigns run by ${widget.charityName}!'),
                sizedBox(5, 0),
                getCampaignsList(context, () {
                  setState(() {});
                }, campaigns),
                sizedBox(10, 0),
                getHomeHeader(context, 'Similar Charities',
                    'Campaigns similar to ${widget.charityName}!'),
                sizedBox(5, 0),
                getCharitiesList(context, () {
                  setState(() {});
                }, npo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
