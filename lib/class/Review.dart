

import 'package:intl/intl.dart';

import 'User.dart';

class Review {
  final String id;
  final String userid;
  final String actividadid;
  final String comment;
  final int rating;
  final DateTime timestamp;
  final int likes;
  final List<ReviewResponse> responses;

  Review({
    required this.id,
    required this.userid,
    required this.comment,
    required this.rating,
    required this.timestamp,
    required this.actividadid,
    this.likes = 0,
    this.responses = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      actividadid: json['actividadid'] ?? '',
      userid: json['userid'] ?? '',
      comment: json['comment'] ?? '',
      rating: json['rating'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      likes: json['likes'] ?? 0,
      responses: (json['responses'] as List<dynamic>).map((item) => ReviewResponse.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userid': userid,
      'actividadid':actividadid,
      'comment': comment,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
      'responses': responses.map((response) => response.toJson()).toList(),
    };
  }
}

class ReviewResponse {
  final String id;
  final String comment;
  final String userid;
  final String response;
  final DateTime timestamp;

  ReviewResponse({
    required this.id,
    required this.comment,
    required this.userid,
    required this.response,
    required this.timestamp,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'] ?? '',
      comment: json['comment'] ?? '',
      userid: json['user'] ?? '',
      response: json['response'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return {
      'id': id,
      'comment': comment,
      'userid': userid,
      'respuesta': response,
      'timestamp': dateFormat.format(timestamp),
    };
  }
}
