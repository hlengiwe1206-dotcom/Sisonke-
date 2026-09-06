onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HelpRequestDetailScreen(
        request: request,
      ),
    ),
  );
},
