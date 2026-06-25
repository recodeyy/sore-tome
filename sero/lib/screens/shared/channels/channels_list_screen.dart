import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sero/providers/shared/channels_provider.dart';
import 'channel_chat_screen.dart';

class ChannelsListScreen extends ConsumerWidget {
  const ChannelsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: channelsAsync.when(
        data: (channels) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final ch = channels[index];
            return ListTile(
              title: Text(ch.name),
              subtitle: Text(ch.description),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: ch)),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}









