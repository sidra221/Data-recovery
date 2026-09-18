import 'package:flutter/material.dart';

import '../../core/api_error_text.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../providers/auth_provider.dart';
import 'app_button.dart';
import 'soft_surface.dart';

enum _NotifyStep { channel, preview }

class NotifyCustomerSheet extends ConsumerStatefulWidget {
  const NotifyCustomerSheet({super.key, required this.jobId});

  final int jobId;

  static Future<void> show(
    BuildContext context, {
    required int jobId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => NotifyCustomerSheet(jobId: jobId),
    );
  }

  @override
  ConsumerState<NotifyCustomerSheet> createState() => _NotifyCustomerSheetState();
}

class _NotifyCustomerSheetState extends ConsumerState<NotifyCustomerSheet> {
  _NotifyStep _step = _NotifyStep.channel;
  bool _isLoadingInvoice = false;
  bool _isSending = false;
  bool _isEditing = false;

  final _messageController = TextEditingController();
  String? _whatsappUrl;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsAppPreview() async {
    final l = L.of(context);
    setState(() => _isLoadingInvoice = true);
    try {
      final invoice = await ref.read(apiClientProvider).getInvoice(widget.jobId);
      if (!mounted) return;
      _messageController.text = invoice['share_text'] as String? ?? '';
      _whatsappUrl = invoice['whatsapp_url'] as String?;
      setState(() {
        _step = _NotifyStep.preview;
        _isEditing = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(apiErrorText(l, error, fallback: l.failedToLoadInvoiceText));
    } catch (_) {
      if (!mounted) return;
      _showError(l.failedToLoadInvoiceText);
    } finally {
      if (mounted) setState(() => _isLoadingInvoice = false);
    }
  }

  Future<void> _sendWhatsApp() async {
    final l = L.of(context);
    if (_isSending) return;
    final rawUrl = _whatsappUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      _showError(l.whatsappUnavailable);
      return;
    }

    setState(() => _isSending = true);
    try {
      final result = await ref.read(apiClientProvider).sendInvoice(
            widget.jobId,
            message: _messageController.text,
          );
      if (!mounted) return;

      final autoSend = result['auto_send'];
      final sentAutomatically = autoSend is Map && autoSend['sent'] == true;
      if (sentAutomatically) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l.sentAutomatically)),
          );
        Navigator.of(context).pop();
        return;
      }

      final uri = _launchUri(rawUrl, _messageController.text);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('could not launch');
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(apiErrorText(l, error, fallback: l.failedToRecordSend));
    } catch (_) {
      if (!mounted) return;
      _showError(l.failedToOpenWhatsapp);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Uri _launchUri(String rawUrl, String message) {
    final uri = Uri.parse(rawUrl);
    if (message.trim().isEmpty) return uri;
    return uri.replace(queryParameters: {'text': message});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.notifications_active, color: Color(0xFF22C55E)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.notifyDeviceReady,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            if (_step == _NotifyStep.channel) ...[
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  l.sendPickupNotification,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ),
              _ChannelCard(
                label: l.whatsapp,
                background: const Color(0xFFDBF8E5),
                iconColor: const Color(0xFF22C55E),
                icon: Icons.chat_bubble_outline,
                enabled: !_isLoadingInvoice,
                isLoading: _isLoadingInvoice,
                onTap: _openWhatsAppPreview,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isEditing
                    ? TextFormField(
                        controller: _messageController,
                        maxLines: 8,
                        minLines: 4,
                        enabled: !_isSending,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )
                    : Text(
                        _messageController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                          height: 1.4,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => setState(() => _isEditing = true),
                    child: Text(
                      l.edit,
                      style: TextStyle(color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    label: l.send,
                    width: 140,
                    isLoading: _isSending,
                    onPressed: _sendWhatsApp,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.label,
    required this.background,
    required this.iconColor,
    required this.icon,
    this.enabled = true,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final Color background;
  final Color iconColor;
  final IconData icon;
  final bool enabled;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: 20,
      color: background,
      shadowColor: iconColor.withValues(alpha: 0.12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: double.infinity,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.18),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
