import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

/// App-wide scaffold that provides consistent styling and the custom loader
/// to be used across all screens in the app.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool isLoading;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;
  final String? errorMessage;
  final Function()? onErrorDismiss;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.isLoading = false,
    this.centerTitle = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
    this.errorMessage,
    this.onErrorDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              centerTitle: centerTitle,
              title: Text(
                title!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              leading: leading ?? 
                (Navigator.canPop(context) 
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.back, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ) 
                  : null),
              actions: actions,
              backgroundColor: backgroundColor ?? Colors.white,
              elevation: 0,
            )
          : null,
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: CupertinoColors.destructiveRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle,
                      color: CupertinoColors.destructiveRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                    ),
                    if (onErrorDismiss != null)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: onErrorDismiss,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.destructiveRed,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: AppLoader(isLoading: isLoading, child: body),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// App-wide screen base that provides a default layout with gradient background and styling
class AppScreen extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final String? errorMessage;
  final Function()? onErrorDismiss;

  const AppScreen({
    Key? key,
    required this.child,
    this.isLoading = false,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.appBar,
    this.title,
    this.leading,
    this.actions,
    this.errorMessage,
    this.onErrorDismiss,
  }) : super(key: key);

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (appBar != null) return appBar;
    if (title == null) return null;

    return AppBar(
      centerTitle: false,
      title: Text(
        title!,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: leading ?? 
        (Navigator.canPop(context) 
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.back, size: 28),
              onPressed: () => Navigator.pop(context),
            ) 
          : null),
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildErrorBanner() {
    if (errorMessage == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.destructiveRed.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.destructiveRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                ),
              ),
            ),
            if (onErrorDismiss != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onErrorDismiss,
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.destructiveRed,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: CupertinoColors.systemBackground,
      body: AppLoader(
        isLoading: isLoading,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF2F6FF), Color(0xFFF9F9F9)],
                ),
              ),
            ),
            
            // Background decorative elements
            Positioned(
              top: -120,
              right: -80,
              child: _circle(CupertinoColors.systemBlue.withOpacity(0.1), 250),
            ),
            
            Positioned(
              bottom: -80,
              left: -50,
              child: _circle(CupertinoColors.systemIndigo.withOpacity(0.08), 200),
            ),
            
            // Main content with error banner
            SafeArea(
              child: Column(
                children: [
                  if (errorMessage != null) 
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildErrorBanner(),
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Helper widget for creating stylized input fields with a consistent design
class AppFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool isRequired;
  final String? placeholder;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final Function()? onTap;
  final bool readOnly;

  const AppFormField({
    Key? key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.isRequired = true,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.onTap,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                CupertinoTextField(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  maxLines: maxLines,
                  placeholder: placeholder ?? 'Enter ${label.toLowerCase()}',
                  decoration: null,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E1E1E),
                  ),
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  suffix: suffix,
                  prefix: prefix,
                  onTap: onTap,
                  readOnly: readOnly || onTap != null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button with consistent styling for primary actions
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      color: isPrimary ? const Color(0xFF0A84FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary ? CupertinoColors.white : const Color(0xFF0A84FF),
              ),
            ),
    );
  }
}

/// Selector widget with consistent styling for dropdown-like pickers
class AppSelector extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onPressed;
  final bool isRequired;

  const AppSelector({
    Key? key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onPressed,
    this.isRequired = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: onPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value.isNotEmpty ? value : placeholder,
                        style: TextStyle(
                          fontSize: 16,
                          color: value.isNotEmpty
                              ? const Color(0xFF1E1E1E)
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        color: CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
