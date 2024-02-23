import 'package:flutter/material.dart';
import 'package:gsoc_pre2/global_connection.dart';
import 'connection_manager_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25),
      textStyle: const TextStyle(fontSize: 20, color: Colors.white),
      minimumSize: const Size(260, 70),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Flutter App'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 50),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ConnectionManagerPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png', width: 400),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => rebootLG(),
              style: buttonStyle,
              child:
                  const Text('Reboot', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => moveToHomeCity(),
              style: buttonStyle,
              child: const Text('Home City',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => makeOrbit(),
              style: buttonStyle,
              child: const Text('Orbit', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => displayImage(),
              style: buttonStyle,
              child: const Text('Image', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await cleanKML();
                await setRefresh();
              },
              style: buttonStyle,
              child: const Text('Clear KML',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void rebootLG() async {
    final bool? shouldReboot = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restart confirmation!'),
          content: const Text('Do you want to reboot the LG?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldReboot == true &&
        GlobalConnection.isConnected &&
        GlobalConnection.sshClient != null) {
      for (var i = 1; i <= GlobalConnection.numberOfScreens; i++) {
        final command = """
          SERVICE=\$(if [ -f /etc/init/lxdm.conf ]; then echo lxdm; elif [ -f /etc/init/lightdm.conf ]; then echo lightdm; fi)
          if [ -z "\$SERVICE" ]; then exit 1; fi
          STATUS=\$(service \$SERVICE status)
          if [[ "\$STATUS" =~ 'stop' ]]; then
            echo lg | sudo -S service \$SERVICE start
          else
            echo lg | sudo -S service \$SERVICE restart
          fi
          sshpass -p lg ssh -x -t lg@lg$i "echo lg | sudo -S service \$SERVICE restart"
        """;

        await GlobalConnection.sshClient!.execute("/home/lg/bin/lg-relaunch");
        await GlobalConnection.sshClient!.execute(command);
      }
    }
  }

  void moveToHomeCity() async {
    String vancouverKML = '''
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
        <Document>
          <LookAt>
            <longitude>-123.1207</longitude>
            <latitude>49.2827</latitude>
            <altitude>0</altitude>
            <range>10000</range>
            <tilt>0</tilt>
            <heading>0</heading>
            <gx:altitudeMode>relativeToGround</gx:altitudeMode>
          </LookAt>
        </Document>
      </kml>
    ''';

    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      await GlobalConnection.sshClient!.execute('> /var/www/html/kmls.txt');
      await GlobalConnection.sshClient!
          .execute("echo '''$vancouverKML''' > /var/www/html/vancouver.kml");
      await GlobalConnection.sshClient!.execute(
          'echo "http://lg1:81/kml/vancouver.kml" > /var/www/html/kmls.txt');
      await GlobalConnection.sshClient!.execute(
          'echo "flytoview=<LookAt><longitude>-123.1207</longitude><latitude>49.2827</latitude><altitude>0</altitude><range>10000</range><tilt>0</tilt><heading>0</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt');
    }
  }

  void makeOrbit() async {
    String generateOrbitKML() {
      double startLongitude = -123.1207;
      double startLatitude = 49.2827;

      double endLongitude = -122.3321;
      double endLatitude = 47.6062;

      double longitudeIncrement = (endLongitude - startLongitude) / 36;
      double latitudeIncrement = (endLatitude - startLatitude) / 36;

      String flyToElements = List.generate(36, (index) {
        double currentLongitude = startLongitude + (index * longitudeIncrement);
        double currentLatitude = startLatitude + (index * latitudeIncrement);
        return '''
      <gx:FlyTo>
        <gx:duration>10</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>$currentLongitude</longitude>
          <latitude>$currentLatitude</latitude>
          <altitude>5000</altitude>
          <heading>0</heading>
          <tilt>45</tilt>
          <range>5000</range>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>
    ''';
      }).join("\n");

      return '''
<?xml version="1.0" encoding="UTF-8"?>
  <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>From Vancouver Tour</name>
    <gx:Tour>
      <name>Travel Tour</name>
      <gx:Playlist>
        $flyToElements
      </gx:Playlist>
    </gx:Tour>
  </Document>
  </kml>
''';
    }

    String orbitKML = generateOrbitKML();

    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      await GlobalConnection.sshClient!.execute('> /var/www/html/kmls.txt');
      await GlobalConnection.sshClient!
          .execute("echo '''$orbitKML''' > /var/www/html/TravelTour.kml");
      await GlobalConnection.sshClient!.execute(
          "echo 'http://lg1:81/TravelTour.kml' >> /var/www/html/kmls.txt");
      await GlobalConnection.sshClient!
          .execute('echo "playtour=Travel Tour" > /tmp/query.txt');
    }
  }

  Future<void> displayImage() async {
    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      String kmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
    <Document id="logo">
         <name>Image Display</name>
             <Folder>
                  <name>Image Overlay</name>
                  <ScreenOverlay>
                      <name>Display Image</name>
                      <Icon><href>https://raw.githubusercontent.com/ryanmckim/GSoC_2024_Pre2/main/assets/name.png</href></Icon>
                      <overlayXY x="0.5" y="1" xunits="fraction" yunits="fraction"/>
                      <screenXY x="0.5" y="0.9" xunits="fraction" yunits="fraction"/>
                      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
                      <size x="400" y="400" xunits="pixels" yunits="pixels"/>
                  </ScreenOverlay>
             </Folder>
    </Document>
</kml>
''';
      int rightScreen = (GlobalConnection.numberOfScreens / 2).floor() + 1;

      await GlobalConnection.sshClient!.execute(
          "echo '$kmlContent' > /var/www/html/kml/slave_$rightScreen.kml");
    }
  }

  Future<void> cleanKML() async {
    if (GlobalConnection.isConnected && GlobalConnection.sshClient != null) {
      String kmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
  </Document>
</kml>''';
      int rightScreen = (GlobalConnection.numberOfScreens / 2).floor() + 1;

      await GlobalConnection.sshClient!.execute(
          "echo '$kmlContent' > /var/www/html/kml/slave_$rightScreen.kml");
    }
  }

  setRefresh() async {
    String password = GlobalConnection.clientPassword;
    for (var i = 2; i <= GlobalConnection.numberOfScreens; i++) {
      String kmlFileLocation =
          '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href>';
      String changeRefresh =
          '<href>##LG_PHPIFACE##kml\\/slave_$i.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';

      await GlobalConnection.sshClient!.execute(
          'sshpass -p $password ssh -t lg$i \'echo $password | sudo -S sed -i "s/$changeRefresh/$kmlFileLocation/" ~/earth/kml/slave/myplaces.kml\'');
      await GlobalConnection.sshClient!.execute(
          'sshpass -p $password ssh -t lg$i \'echo $password | sudo -S sed -i "s/$kmlFileLocation/$changeRefresh/" ~/earth/kml/slave/myplaces.kml\'');
    }
  }
}
