import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class itemDetail extends StatelessWidget {
  const itemDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text('test sliver'),
          floating: false,
          expandedHeight: 200.0,
          flexibleSpace: FlexibleSpaceBar(
            background: CachedNetworkImage(
              imageUrl: '',
            ),
          ),
        ),
        SliverList(
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {}),
        ),
      ],
    );
  }
}
