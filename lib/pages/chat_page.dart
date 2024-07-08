import 'dart:io';

import 'package:chatbond/models/chat.dart';
import 'package:chatbond/models/message.dart';
import 'package:chatbond/models/user_profile.dart';
import 'package:chatbond/services/alert_service.dart';
import 'package:chatbond/services/auth_service.dart';
import 'package:chatbond/services/database_service.dart';
import 'package:chatbond/services/media_service.dart';
import 'package:chatbond/services/storage_service.dart';
import 'package:chatbond/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;
  const ChatPage({super.key, required this.chatUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatUser? currentUser, otherUser;
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late AlertService _alertService;
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  final TextEditingController _messageController = TextEditingController();

  late List uids;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _alertService = _getIt.get<AlertService>();
    currentUser = ChatUser(
        id: _authService.user!.uid, firstName: _authService.user!.displayName);
    otherUser =
        ChatUser(id: widget.chatUser.uid!, firstName: widget.chatUser.name);
    _focusNode.addListener(_onFocusChange);
    uids = [_authService.user!.uid, widget.chatUser.uid!];
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isEmojiVisible = false; // Hide emoji picker when keyboard appears
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(widget.chatUser.pfpURL!)),
            const SizedBox(
              width: 10,
            ),
            Text(
              widget.chatUser.name!,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            onSelected: (String result) {
              if (result == 'clear') {
                _clearChat(context, getChatId(uids));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return StreamBuilder(
        stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
        builder: (context, snapshot) {
          Chat? chat = snapshot.data?.data();
          List<ChatMessage> messages = [];
          if (chat != null && chat.messages != null) {
            messages = _generateChatMessagesList(chat.messages!);
          }
          return Column(
            children: [
              Expanded(
                child: DashChat(
                    messageOptions: MessageOptions(
                      showOtherUsersAvatar: true,
                      showTime: true,
                      showOtherUsersName: false,
                      borderRadius: 15,
                      currentUserContainerColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      containerColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      timeTextColor: Colors.black,
                      currentUserTimeTextColor: Colors.white,
                    ),
                    inputOptions: InputOptions(
                      focusNode: _focusNode,
                      textController: _messageController,
                      inputToolbarStyle: const BoxDecoration(
                        color: Colors.white,
                      ),
                      alwaysShowSend: true,
                      inputDecoration: InputDecoration(
                          filled: true,
                          fillColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          isDense: true,
                          hintText: "Type a messeage...",
                          prefixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isEmojiVisible = !_isEmojiVisible;
                                  if (_isEmojiVisible) {
                                    _focusNode
                                        .unfocus(); // Ensure keyboard is dismissed when emoji picker is shown
                                  } else {
                                    _focusNode.requestFocus();
                                  }
                                });
                              },
                              iconSize: 25,
                              color: Theme.of(context).colorScheme.primary,
                              icon: Icon(_isEmojiVisible
                                  ? Icons.keyboard
                                  : Icons.emoji_emotions)),
                          suffixIcon: _mediaMessageButton(),
                          border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(30))),
                    ),
                    currentUser: currentUser!,
                    onSend: _sendMessage,
                    messages: messages),
              ),
              _isEmojiVisible
                  ? SizedBox(child: _emojiPickerButton())
                  : const SizedBox.shrink()
            ],
          );
        });
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        Message message = Message(
            senderID: chatMessage.user.id,
            content: chatMessage.medias!.first.url,
            messageType: MessageType.Image,
            sentAt: Timestamp.fromDate(chatMessage.createdAt));
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      Message message = Message(
          senderID: currentUser!.id,
          content: chatMessage.text,
          messageType: MessageType.Text,
          sentAt: Timestamp.fromDate(chatMessage.createdAt));
      await _databaseService.sendChatMessage(
          currentUser!.id, otherUser!.id, message);
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            createdAt: m.sentAt!.toDate(),
            medias: [
              ChatMedia(url: m.content!, fileName: "", type: MediaType.image)
            ]);
      } else {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            text: m.content!,
            createdAt: m.sentAt!.toDate());
      }
    }).toList();
    chatMessages.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    return chatMessages;
  }

  Widget _mediaMessageButton() {
    return IconButton(
        iconSize: 25,
        onPressed: () async {
          File? file = await _mediaService.getImageFromGallery();
          if (file != null) {
            String chatID =
                generateChatID(uid1: currentUser!.id, uid2: otherUser!.id);
            String? downloadURL = await _storageService.uploadImageToChat(
                file: file, chatID: chatID);
            if (downloadURL != null) {
              ChatMessage chatMessage = ChatMessage(
                  user: currentUser!,
                  createdAt: DateTime.now(),
                  medias: [
                    ChatMedia(
                        url: downloadURL, fileName: "", type: MediaType.image)
                  ]);
              _sendMessage(chatMessage);
            }
          }
        },
        icon: Icon(
          Icons.image,
          color: Theme.of(context).colorScheme.primary,
        ));
  }

  Widget _emojiPickerButton() {
    return EmojiPicker(
      config: const Config(
          swapCategoryAndBottomBar: true,
          bottomActionBarConfig: BottomActionBarConfig(
              showBackspaceButton: false, showSearchViewButton: false)),
      onEmojiSelected: (category, emoji) {
        _insertEmoji(emoji.emoji);
      },
    );
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    final newSelection =
        TextSelection.collapsed(offset: selection.start + emoji.length);
    _messageController.value = _messageController.value.copyWith(
      text: newText,
      selection: newSelection,
    );
  }

  String getChatId(List uids) {
    String chatID;
    uids.sort();
    chatID = chatID = uids.fold("", (id, uid) => "$id$uid");
    return chatID;
  }

  void _clearChat(BuildContext context, String chatId) async {
    try {
      await _databaseService.clearChat(chatId);
      _alertService.showToast(
          text: 'Chat cleared successfully', icon: Icons.check_circle_outline);
    } catch (e) {
      _alertService.showToast(text: 'Failed to clear chat');
    }
  }
}
