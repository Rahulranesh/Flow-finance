import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class AddButton extends StatelessWidget {
  const AddButton({
    Key? key,
    required this.onTap,
    this.margin = EdgeInsetsDirectional.zero,
    this.padding = EdgeInsetsDirectional.zero,
    this.width = 110,
    this.height = 52,
    this.openPage,
    this.borderRadius = 15,
    this.icon,
    this.afterOpenPage,
    this.onOpenPage,
    this.labelUnder,
  }) : super(key: key);

  final VoidCallback onTap;
  final EdgeInsetsDirectional margin;
  final EdgeInsetsDirectional padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? openPage;
  final IconData? icon;
  final Function? afterOpenPage;
  final Function? onOpenPage;
  final String? labelUnder;

  @override
  Widget build(BuildContext context) {
    Color color = appStateSettings["materialYou"]
        ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
        : getColor(context, "lightDarkAccentHeavy").withOpacity(0.4);
    Color bgColor = appStateSettings["materialYou"]
        ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4)
        : Theme.of(context).canvasColor.withOpacity(0.5);

    Widget getButton(onTap) {
      return Tappable(
        color: bgColor,
        borderRadius: borderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2.0,
              color: color.withOpacity(0.2),
            ),
            borderRadius: BorderRadiusDirectional.circular(borderRadius),
          ),
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Icon(
                  icon ??
                      (appStateSettings["outlinedIcons"]
                          ? Icons.add_outlined
                          : Icons.add_rounded),
                  size: 38,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (labelUnder != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8),
                  child: TextFont(
                    text: labelUnder ?? "",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    textColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        onTap: () {
          onTap();
        },
      );
    }

    if (openPage != null) {
      return Padding(
        padding: margin,
        child: OpenContainerNavigation(
          openPage: openPage!,
          button: (openPage) {
            return getButton(openPage);
          },
          borderRadius: borderRadius,
          onClosed: () {
            if (afterOpenPage != null) afterOpenPage!();
          },
          onOpen: () {
            if (onOpenPage != null) onOpenPage!();
          },
        ),
      );
    }
    Widget button = getButton(onTap);
    return Padding(
      padding: margin,
      child: button,
    );
  }
}
