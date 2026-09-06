Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HelpRequestDetailScreen(
      request: {
        'id': request.id,
        'title': request.title,
        'description': request.description,
        'category': request.category,
        'status': request.status,
        'urgent': request.urgent,
        'created_at': request.createdAt?.toIso8601String(),
      },
    ),
  ),
);
