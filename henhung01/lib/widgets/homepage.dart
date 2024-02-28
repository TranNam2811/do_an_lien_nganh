import 'package:flutter/material.dart';
import 'pass.dart';
class MyHomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home',
        style:  TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 30,
          )
        ),
        backgroundColor: Colors.blueAccent,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(height: 100),
          Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(20.0)),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyPass()),
                    );
                    // Navigator.of(context).popAndPushNamed("/pass");
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.key,
                        color: Colors.lightBlue,
                        size: 50,
                      ),
                      Text('Change Pass',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      )
                    ],
                  )
              )
            ],
          )
        ],
      ),
    );
  }
}