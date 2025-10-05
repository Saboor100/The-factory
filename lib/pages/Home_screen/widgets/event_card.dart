import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(String) formatDate;

  const EventCard({Key? key, required this.data, required this.formatDate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled Event';
    final location = data['location'] ?? 'TBD';
    final category = data['category'] ?? 'general';
    final startDate = data['startDate'] ?? '';
    final ticketTypes = data['ticketTypes'] as List? ?? [];

    String price = 'Free';
    if (ticketTypes.isNotEmpty) {
      final minPrice = ticketTypes
          .map((t) => t['price'] as num? ?? 0)
          .reduce((a, b) => a < b ? a : b);
      price = minPrice > 0 ? '\$${minPrice.toInt()}' : 'Free';
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF3A3A3A),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Center(
              child: Text(
                formatDate(startDate),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB8FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    category.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              price,
              style: const TextStyle(
                color: Color(0xFFB8FF00),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
