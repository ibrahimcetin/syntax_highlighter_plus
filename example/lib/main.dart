import 'package:flutter/material.dart';

import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlighter Plus',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('syntax_highlighter_plus')),
        body: const HighlightedText(),
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText({super.key});

  @override
  Widget build(BuildContext context) {
    final syntaxHighlighter = SyntaxHighlighterPlus(theme: 'github-dark');
    final highlightFuture = syntaxHighlighter.highlight(
      'python',
      _pythonSample,
    );

    return FutureBuilder<TextSpan>(
      future: highlightFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: SelectableText('Error: ${snapshot.error}'));
        }

        // Get the highlighted text span, falling back to non-highlighted text if not available.
        final span = snapshot.data ?? const TextSpan(text: _pythonSample);

        // Display the highlighted text in a scrollable view.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText.rich(
              span,
              style: const TextStyle(fontFamily: 'monospace', height: 1.6),
            ),
          ),
        );
      },
    );
  }
}

const _pythonSample = r'''
import json
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class User:
    id: int
    username: str
    email: str
    is_active: bool = True

class UserManager:
    """Manages user data and operations."""
    
    def __init__(self):
        self._users: List[User] = []
        
    def add_user(self, username: str, email: str) -> User:
        user_id = len(self._users) + 1
        user = User(id=user_id, username=username, email=email)
        self._users.append(user)
        return user
        
    def get_user(self, user_id: int) -> Optional[User]:
        for user in self._users:
            if user.id == user_id:
                return user
        return None
        
    def export_data(self) -> str:
        return json.dumps([user.__dict__ for user in self._users], indent=4)

if __name__ == '__main__':
    manager = UserManager()
    manager.add_user("alice", "alice@example.com")
    manager.add_user("bob", "bob@example.com")
    
    print("Exported User Data:")
    print(manager.export_data())
''';
