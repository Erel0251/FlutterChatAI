import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:dart_openai/dart_openai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template/presentation/tab_section.dart';

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<OpenAIChatCompletionChoiceMessageModel> _historychat = [];
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _agent = const types.User(id: 'agent');
  String? counter;

  @override
  // Screen initiation
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      drawer: const HistorySectionScreen(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color.fromARGB(255, 61, 59, 64),
      foregroundColor: Colors.white,
      title: const Text('Chat'),
      centerTitle: true,
    );
  }

  // body: contain an mini appbar to choose role of AI Agent
  // and a listview of chat history
  Widget _buildBody() {
    return Column(
      children: [
        _buildChatBox(),
      ],
    );
  }

  // chat history: contain a listview of chat item
  // with avatar and message, chat of user float to the right
  // and chat of AI Agent float to the left
  Widget _buildChatBox() {
    return Expanded(
      child: FutureBuilder(
        future: listChatHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Chat(
              messages: _loadmessage(snapshot.data),
              onSendPressed: _handleSendPressed,
              user: _user,
            );
          } else {
            return Chat(
              messages: _loadmessage([]),
              onSendPressed: _handleSendPressed,
              user: _user,
            );
          }
        },
      ),
    );
  }

  // get list message, if [] then _loadChatHistory
  dynamic _loadmessage(List<String>? currentChat) {
    if (_messages.isEmpty) {
      return _loadChatHistory(currentChat);
    } else {
      //if it's a last message, then add animation
      return _messages.map((e) => e).toList();
    }
  }

  // load chat history from shared preferences and add it to _messages
  dynamic _loadChatHistory(List<String>? currentChat) {
    if (currentChat != null && currentChat.isNotEmpty) {
      // if index % 2 == 0 then it's user message
      // else it's agent message
      for (int index = 0; index < currentChat.length; index++) {
        final types.Message msg = types.TextMessage(
          author: index % 2 == 0 ? _user : _agent,
          id: index.toString(),
          text: currentChat[index],
        );

        final userMessage = OpenAIChatCompletionChoiceMessageModel(
          role: index % 2 == 0
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
                currentChat[index])
          ],
        );

        _historychat.add(userMessage);
        _messages.insert(0, msg);
      }
    }
    return _messages.map((e) => e).toList();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    _addMessage(types.TextMessage(
      author: _user,
      id: randomString(),
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    // get response from AI Agent
    String response = await _openAIResponse(message.text);

    _addMessage(types.TextMessage(
      author: _agent,
      id: randomString(),
      text: response.toString(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    // update shared preferences
    _updateSharedPreferences(message.text, response);
  }

  void _updateSharedPreferences(
    String userMessage,
    String agentMessage,
  ) async {
    // get the list of topics and current chat from shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? counter = prefs.getStringList('topics');
    String? topic = prefs.getString('topic');

    // if the topic is null, then add the topic to the list
    // as a new topic. If not, then update the position of the topic
    // in the shared preferences
    if (topic == null) {
      if (counter == null) {
        prefs.setStringList('topics', [userMessage]);
        counter = prefs.getStringList('topics');
      } else {
        counter.insert(0, userMessage);
        prefs.setStringList('topics', counter);
      }
      topic = userMessage;
      prefs.setString('topic', userMessage);
      prefs.setStringList(topic, [userMessage, agentMessage]);
    } else {
      // if the topic is already in the first position, then don't do anything
      if (counter!.first != topic) {
        // if the topic is already in the list, then remove it
        if (counter.contains(topic)) {
          counter.remove(topic);
        }
        // add the topic to the index 0 position
        counter.insert(0, topic);
      }
      // update the chat history of the topic
      List<String>? chatList = prefs.getStringList(topic);
      chatList!.add(userMessage);
      chatList.add(agentMessage);
      prefs.setStringList(topic, chatList);
    }

    // update to shared preferences
    prefs.setStringList('topics', counter!);
  }

  Future<List<String>> listChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? counter = prefs.getString('topic');
    if (counter == null) {
      return [];
    } else {
      List<String>? chatList = prefs.getStringList(counter);
      if (chatList == null) {
        return [];
      } else {
        return chatList;
      }
    }
  }

  Future<String> _openAIResponse(String message) async {
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.user,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(message)
      ],
    );

    _historychat.add(userMessage);

    final chatCompletion = await OpenAI.instance.chat.create(
      model: 'gpt-3.5-turbo-1106',
      n: 1,
      messages: _historychat,
    );

    String response = chatCompletion.choices.first.message.content![0].text!;

    _historychat.add(OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.assistant,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(response)
        ]));
    // or content: chatCompletion.choices.first.message.content

    return response;
  }
}
