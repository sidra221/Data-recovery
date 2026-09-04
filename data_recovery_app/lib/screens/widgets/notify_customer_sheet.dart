import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../providers/auth_provider.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotifyCustomerSheet(jobId: jobId),
    );
  }

  @override
  ConsumerState<NotifyCustomerSheet> createState() => _NotifyCustomerSheetState();
}

class _NotifyCustomerSheetState extends ConsumerState<NotifyCustomerSheet> {
  static const _gradientStart = Color(0xFF5CCBED);
  static const _gradientEnd = Color(0xFF2EABD2);

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
      _showError(error.message.isNotEmpty ? error.message : 'تعذّر جلب نص الفاتورة');
    } catch (_) {
      if (!mounted) return;
      _showError('تعذّر جلب نص الفاتورة');
    } finally {
      if (mounted) setState(() => _isLoadingInvoice = false);
    }
  }

  Future<void> _sendWhatsApp() async {
    if (_isSending) return;
    final rawUrl = _whatsappUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      _showError('رابط واتساب غير متوفر');
      return;
    }

    setState(() => _isSending = true);
    try {
      final uri = _launchUri(rawUrl, _messageController.text);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('could not launch');
      }
      await ref.read(apiClientProvider).sendInvoice(widget.jobId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message.isNotEmpty ? error.message : 'تعذّر تسجيل الإرسال');
    } catch (_) {
      if (!mounted) return;
      _showError('تعذّر فتح واتساب أو تسجيل الإرسال');
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
              children: [
                const Icon(Icons.notifications_outlined, color: Color(0xFF111827)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notify Customer - Device Ready',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Send pickup notification',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
              ),
              _ChannelCard(
                label: 'WhatsApp',
                background: const Color(0xFFDBF8E5),
                iconColor: const Color(0xFF22C55E),
                icon: Icons.chat_bubble_outline,
                enabled: !_isLoadingInvoice,
                isLoading: _isLoadingInvoice,
                onTap: _openWhatsAppPreview,
              ),
              const SizedBox(height: 12),
              // TODO: SMS not supported by backend yet
              const Opacity(
                opacity: 0.45,
                child: IgnorePointer(
                  child: _ChannelCard(
                    label: 'SMS',
                    background: Color(0xFFDEEBFF),
                    iconColor: Color(0xFF3B82F6),
                    icon: Icons.sms_outlined,
                    enabled: false,
                  ),
                ),
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
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [_gradientStart, _gradientEnd],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSending ? null : _sendWhatsApp,
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 44,
                          width: 120,
                          child: Center(
                            child: _isSending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
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
