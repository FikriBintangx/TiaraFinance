import 'package:cloud_firestore/cloud_firestore.dart';

// Voting/Polling Models
class VotingModel {
  final String id;
  final String title;
  final String description;
  final List<String> options;
  final DateTime createdAt;
  final DateTime endDate;
  final String createdBy;
  final bool isActive;
  final Map<String, int> votes; // option -> vote count

  VotingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
    required this.createdAt,
    required this.endDate,
    required this.createdBy,
    required this.isActive,
    required this.votes,
  });

  factory VotingModel.fromMap(Map<String, dynamic> map, String id) {
    return VotingModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      endDate: (map['end_date'] as Timestamp).toDate(),
      createdBy: map['created_by'] ?? '',
      isActive: map['is_active'] ?? true,
      votes: Map<String, int>.from(map['votes'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'options': options,
      'created_at': Timestamp.fromDate(createdAt),
      'end_date': Timestamp.fromDate(endDate),
      'created_by': createdBy,
      'is_active': isActive,
      'votes': votes,
    };
  }

  int get totalVotes => votes.values.fold(0, (sum, count) => sum + count);
  
  bool get hasEnded => DateTime.now().isAfter(endDate);
}

class VoteRecordModel {
  final String id;
  final String votingId;
  final String userId;
  final String selectedOption;
  final DateTime timestamp;

  VoteRecordModel({
    required this.id,
    required this.votingId,
    required this.userId,
    required this.selectedOption,
    required this.timestamp,
  });

  factory VoteRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return VoteRecordModel(
      id: id,
      votingId: map['voting_id'] ?? '',
      userId: map['user_id'] ?? '',
      selectedOption: map['selected_option'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voting_id': votingId,
      'user_id': userId,
      'selected_option': selectedOption,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// Event/Jadwal Kegiatan Models
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String createdBy;
  final DateTime createdAt;
  final List<String> attendees; // user IDs yang RSVP

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.createdBy,
    required this.createdAt,
    required this.attendees,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate: (map['event_date'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      attendees: List<String>.from(map['attendees'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'event_date': Timestamp.fromDate(eventDate),
      'location': location,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'attendees': attendees,
    };
  }

  bool get isPast => DateTime.now().isAfter(eventDate);
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }
}
