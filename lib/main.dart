import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Flutter App'),
        ),
        body: Center(
          child: Image.asset('assets/logo.png'),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.restart_alt),
              label: 'Reboot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home City',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.circle),
              label: 'Orbit',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Image',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue[900],
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        rebootLG();
        break;
      case 1:
        moveToHomeCity();
        break;
      case 2:
        makeOrbit();
        break;
      case 3:
        displayImage();
        break;
    }
  }

  void rebootLG() async {
    final bool? shouldReboot = await showDialog<bool>(
      context: navigatorKey.currentContext!,
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

    if (shouldReboot == true) {
      SSHClient client = SSHClient(
        await SSHSocket.connect("192.168.56.102", 22),
        username: "lg",
        onPasswordRequest: () => "lg",
      );

      for (var i = 1; i <= 3; i++) {
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

        await client.execute("/home/lg/bin/lg-relaunch");
        await client.execute(command);
      }
    }
  }

  void moveToHomeCity() async {
    SSHClient client = SSHClient(
      await SSHSocket.connect("192.168.56.102", 22),
      username: "lg",
      onPasswordRequest: () => "lg",
    );

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

    await client.execute('> /var/www/html/kmls.txt');
    await client
        .execute("echo '''$vancouverKML''' > /var/www/html/kml/vancouver.kml");
    await client.execute(
        'echo "http://lg1:81/kml/vancouver.kml" > /var/www/html/kmls.txt');
    await client.execute(
        'echo "flytoview=<LookAt><longitude>-123.1207</longitude><latitude>49.2827</latitude><altitude>0</altitude><range>10000</range><tilt>0</tilt><heading>0</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt');
  }

  void makeOrbit() async {
    SSHClient client = SSHClient(
      await SSHSocket.connect("192.168.56.102", 22),
      username: "lg",
      onPasswordRequest: () => "lg",
    );

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

    await client.execute('> /var/www/html/kmls.txt');
    await client.execute("echo '''$orbitKML''' > /var/www/html/TravelTour.kml");
    await client.execute(
        "echo 'http://lg1:81/TravelTour.kml' >> /var/www/html/kmls.txt");
    await client.execute('echo "playtour=Travel Tour" > /tmp/query.txt');
  }

  Future<void> displayImage() async {
    SSHClient client = SSHClient(
      await SSHSocket.connect("192.168.56.102", 22),
      username: "lg",
      onPasswordRequest: () => "lg",
    );

    await client.execute(
        "sshpass -p lg ssh -o StrictHostKeyChecking=no -t lg@lg2 'DISPLAY=:0 feh --geometry 400x400 \"/home/lg/Downloads/name.png\" --borderless'");
  }
}
