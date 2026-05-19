import 'package:flutter/material.dart';

class NavBarItems {
  final IconData? icon;
  final Widget? customIcon;
  final String title;

  NavBarItems({
    this.icon,
    this.customIcon,
    required this.title,
  });
}

class FloatingNavigationBar extends StatelessWidget {
  final double barHeight;
  final double? barWidth;
  final double? iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final List<NavBarItems> items;
  final ValueChanged<int> onChanged;
  final Color indicatorColor;
  final double indicatorHeight;
  final double indicatorWidth;
  final int currentIndex;

  const FloatingNavigationBar({
    Key? key,
    required this.items,
    required this.onChanged,
    required this.currentIndex,
    this.barHeight = 80.0,
    this.barWidth = 400.0,
    this.iconColor,
    this.iconSize,
    this.textStyle,
    this.backgroundColor,
    this.indicatorColor = Colors.black,
    this.indicatorHeight = 5.0,
    this.indicatorWidth = 8.0,
  })  : assert(
          (items.length <= 5),
          "NavBarItems can't contain more than 5 items",
        ),
        assert(
          barHeight <= 100,
          "\n******\nHeight should be less than or equal to 100\n******\n",
        ),
        assert(
          indicatorWidth <= 15 || indicatorHeight <= 15,
          "\n******\n Too much height given to tab indicator \n******\n",
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: barHeight,
      width: barWidth,
      margin: const EdgeInsets.symmetric(
        horizontal: 15.0,
        vertical: 20.0,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (i) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Container(
              width: 70.0,
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  items[i].customIcon ??
                      Icon(
                        items[i].icon,
                        size: iconSize,
                        color: iconColor,
                      ),
                  Text(
                    items[i].title,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Visibility(
                    visible: currentIndex == i,
                    child: Container(
                      height: indicatorHeight,
                      width: indicatorWidth,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: indicatorColor,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
