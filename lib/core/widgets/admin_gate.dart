import 'package:flutter/material.dart';
import 'package:ting/core/services/admin_service.dart';

/// A widget that shows different content based on admin status
class AdminGate extends StatefulWidget {
  final Widget adminWidget;
  final Widget nonAdminWidget;
  final Widget? loadingWidget;

  const AdminGate({
    Key? key,
    required this.adminWidget,
    required this.nonAdminWidget,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  bool? _isAdmin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminService.isCurrentUserAdminAsync();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? const CircularProgressIndicator();
    }

    return _isAdmin == true ? widget.adminWidget : widget.nonAdminWidget;
  }
}

/// A builder widget for more complex admin-specific UI
class AdminBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isAdmin, bool isLoading)
  builder;

  const AdminBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  State<AdminBuilder> createState() => _AdminBuilderState();
}

class _AdminBuilderState extends State<AdminBuilder> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminService.isCurrentUserAdminAsync();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isAdmin, _isLoading);
  }
}
