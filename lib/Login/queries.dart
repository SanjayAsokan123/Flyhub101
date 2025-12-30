const String loginMutation = r'''
  mutation Login($email: String!, $password: String!) {
    login(email: $email, password: $password) {
      id
      name
      email
      isAdmin
      token
    }
  }
''';
