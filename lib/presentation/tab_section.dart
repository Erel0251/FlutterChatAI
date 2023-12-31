import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template/presentation/main_screen.dart';

class HistorySectionScreen extends StatefulWidget {
  const HistorySectionScreen({Key? key}) : super(key: key);

  @override
  State<HistorySectionScreen> createState() => _HistorySectionScreenState();
}

class _HistorySectionScreenState extends State<HistorySectionScreen> {
  //shared preferences:---------------------------------------------------------------
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // Widget Drawer with 2 part
  // History list on the up top
  // New Chat button on the bottom
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _buildBody(),
    );
  }

  // Body of the drawer, contains the history list and new chat button
  // the history is get from the shared preferences named topics
  Widget _buildBody() {
    return Column(
      children: [
        _historyList(),
        _newChatSection(),
      ],
    );
  }

  // History List contains the list of all the stream chats that the user has
  // the data is get from the shared preferences named topics
  Widget _historyList() {
    return FutureBuilder<SharedPreferences>(
      future: _prefs,
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.hasData &&
            snapshot.data!.getStringList('topics') != null) {
          return Expanded(
            child: ListView.builder(
              itemCount: snapshot.data!.getStringList('topics')!.length,
              itemBuilder: (BuildContext context, int index) {
                return _historyListItem(
                  snapshot.data!.getStringList('topics')![index],
                  index,
                );
              },
            ),
          );
        } else {
          return const Expanded(
            child: Center(
              child: Text('No History'),
            ),
          );
        }
      },
    );
  }

  // listItem that is a button contains first message of the chat
  // and the delete listItem button float to the right
  Widget _historyListItem(String firstMessage, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 191, 207, 231),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          // color: Color.fromARGB(255, 191, 207, 231),
          color: Color.fromARGB(255, 248, 237, 255),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          // _chatController.changeTopic(firstMessage);
          // store chosen topic to shared preferences
          // so that it can be used in chat screen
          /*
          _prefs.then((SharedPreferences prefs) {
            prefs.setString('topic', firstMessage);
          });
          */

          await _prefs.then((SharedPreferences prefs) {
            prefs.setString('topic', firstMessage);
          });

          // push and remove until the chat screen on file main_screen
          Future.delayed(const Duration(milliseconds: 0), () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const ChatScreen(),
                ),
                (route) => false);
          });
        },
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(5),
                // if it's longer than tab, it will be cutjust like the tab
                child: Text(
                  firstMessage,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            _historyListItemDeleteButton(index),
          ],
        ),
      ),
    );
  }

  // delete button for each listItem
  // when clicked, the item on shared preferences will be deleted
  // and update the list, if the delete one is the last one
  // or the using one, the chat screen will show new chat screen
  Widget _historyListItemDeleteButton(int index) {
    return IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () async {
        _prefs.then((SharedPreferences prefs) {
          final List<String>? counter = prefs.getStringList('topics');

          // remove its content from shared preferences
          prefs.remove(counter![index]);

          if (counter.length == 1) {
            prefs.remove('topic');
          }

          counter.removeAt(index);
          prefs.setStringList('topics', counter);

          // reload the chat screen to make sure the list is updated
          Future.delayed(const Duration(milliseconds: 0), () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => const ChatScreen(),
                ),
                (route) => false);
          });
        });
      },
    );
  }

  Widget _newChatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _newChatButton(),
        const Text('Version: 1.1.0'),
      ],
    );
  }

  // open new chat screen with no data
  // using decoration to make it look like a Elevated button
  Widget _newChatButton() {
    return GestureDetector(
      onTap: () async {
        // _chatController.changeTopic(null);
        // store chosen topic to shared preferences
        // so that it can be used in chat screen
        /*
          _prefs.then((SharedPreferences prefs) {
            prefs.remove('topic');
          });
          */

        await _prefs.then((SharedPreferences prefs) {
          prefs.remove('topic');
        });

        // reload the chat screen to make sure the list is updated
        Future.delayed(const Duration(milliseconds: 0), () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const ChatScreen(),
              ),
              (route) => false);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 191, 207, 231),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            // color: Color.fromARGB(255, 191, 207, 231),
            color: Colors.black12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: const Text('New Chat'),
      ),
    );
  }

  /*
  Widget _newChatButton() {
    return ElevatedButton(
      onPressed: () async {
        // _chatController.changeTopic(null);
        // store chosen topic to shared preferences
        // so that it can be used in chat screen
        /*
        _prefs.then((SharedPreferences prefs) {
          prefs.remove('topic');
        });
        */

        await _prefs.then((SharedPreferences prefs) {
          prefs.remove('topic');
        });

        // reload the chat screen to make sure the list is updated
        Future.delayed(const Duration(milliseconds: 0), () {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const ChatScreen(),
              ),
              (route) => false);
        });
      },
      child: const Text('New Chat'),
    );
  }
  */
}
