import 'package:chatbond/core/utils/firebase_utils.dart';
import 'package:chatbond/features/auth/presentation/providers/auth_provider.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:chatbond/features/chat/presentation/providers/chat_provider.dart';
import 'package:chatbond/features/profile/presentation/providers/profile_provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerStatefulWidget {
  final UserProfileEntity? chatUser;

  const ChatPage({super.key, this.chatUser});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  ChatUser? currentUser, otherUser;
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  final TextEditingController _messageController = TextEditingController();
  late List<String> uids;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    if (widget.chatUser != null) {
      uids = [ref.read(currentUserProvider)!.uid, widget.chatUser!.uid];
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        _isEmojiVisible = false;
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
    final currentAuthUser = ref.watch(currentUserProvider);

    if (currentAuthUser == null || widget.chatUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    currentUser =
        ChatUser(id: currentAuthUser.uid, firstName: currentAuthUser.email);
    otherUser =
        ChatUser(id: widget.chatUser!.uid, firstName: widget.chatUser!.name);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            CircleAvatar(
                radius: 25,
                backgroundImage: widget.chatUser!.pfpURL != null
                    ? NetworkImage(widget.chatUser!.pfpURL!)
                    : const NetworkImage(
                        'https://t3.ftcdn.net/jpg/05/16/27/58/360_F_516275801_f3Fsp17x6HQK0xQgDQEELoTuERO4SsWV.jpg')),
            const SizedBox(width: 10),
            Text(
              widget.chatUser!.name,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: _buildUI(context, currentAuthUser),
    );
  }

  Widget _buildUI(BuildContext context, dynamic currentAuthUser) {
    final chatData = ref
        .watch(chatDataProvider((currentAuthUser.uid, widget.chatUser!.uid)));

    return chatData.when(
      data: (chat) {
        final messages = _generateChatMessagesList(chat.messages);
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
                        hintText: "Type a message...",
                        prefixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isEmojiVisible = !_isEmojiVisible;
                                if (_isEmojiVisible) {
                                  _focusNode.unfocus();
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
                        suffixIcon: _mediaMessageButton(currentAuthUser),
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text("Error loading chat: $error"),
      ),
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    final currentAuthUser = ref.read(currentUserProvider);

    if (currentAuthUser == null) return;

    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        final message = MessageEntity(
            senderID: chatMessage.user.id,
            content: chatMessage.medias!.first.url,
            messageType: MessageType.Image,
            sentAt: chatMessage.createdAt);
        await ref
            .read(sendMessageProvider.notifier)
            .sendMessage(currentAuthUser.uid, widget.chatUser!.uid, message);
      }
    } else {
      final message = MessageEntity(
          senderID: currentAuthUser.uid,
          content: chatMessage.text,
          messageType: MessageType.Text,
          sentAt: chatMessage.createdAt);
      await ref
          .read(sendMessageProvider.notifier)
          .sendMessage(currentAuthUser.uid, widget.chatUser!.uid, message);
    }
    _messageController.clear();
  }

  List<ChatMessage> _generateChatMessagesList(List<MessageEntity> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            createdAt: m.sentAt,
            medias: [
              ChatMedia(url: m.content, fileName: "", type: MediaType.image)
            ]);
      } else {
        return ChatMessage(
            user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
            text: m.content,
            createdAt: m.sentAt);
      }
    }).toList();
    chatMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return chatMessages;
  }

  Widget _mediaMessageButton(dynamic currentAuthUser) {
    return IconButton(
        iconSize: 25,
        onPressed: () async {
          await ref
              .read(getImageFromGalleryProvider.notifier)
              .getImageFromGallery();
          final imageState = ref.read(getImageFromGalleryProvider);
          imageState.whenData((file) async {
            if (file != null) {
              final chatID = generateChatID(
                  uid1: currentAuthUser.uid, uid2: widget.chatUser!.uid);
              await ref
                  .read(uploadChatImageProvider.notifier)
                  .uploadChatImage(file, chatID);

              final uploadState = ref.read(uploadChatImageProvider);
              uploadState.whenData((downloadURL) {
                if (downloadURL != null) {
                  ChatMessage chatMessage = ChatMessage(
                      user: currentUser!,
                      createdAt: DateTime.now(),
                      medias: [
                        ChatMedia(
                            url: downloadURL,
                            fileName: "",
                            type: MediaType.image)
                      ]);
                  _sendMessage(chatMessage);
                }
              });
            }
          });
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
}
