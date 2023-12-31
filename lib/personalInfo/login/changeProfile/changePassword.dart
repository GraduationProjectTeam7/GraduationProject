import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fortest/main.dart';
import 'package:fortest/personalInfo/login/login.dart';

void main() {
  runApp(const MaterialApp(
    home: ChangePasswordScreen(),
  ));
}

void goToAnotherPage(BuildContext context, String pageName) {
  // 버튼에 따라 그에 해당하는 파일로 이동
  switch (pageName) {

    case "LoginScreen":
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      break;

  }
}

class UserData {
  String name;

  String password;
  String email;
  String nickname;
  String? profileImgUrl;

  UserData(
      {required this.name,
        required this.password,
        required this.email,
        required this.nickname,
        required this.profileImgUrl,
      });
}

class ChangePasswordScreen extends StatefulWidget{
  const ChangePasswordScreen({Key? key}) : super(key:key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  UserData userData =
  UserData(name: '',
      email: '',
      nickname: '',
      profileImgUrl: '',
      password: '');
  bool isLoading = true;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  bool _isMatching = false; // 초기값 false


  void checkPasswordMatch() {
    final isMatching =
        _newPasswordController.text == _confirmationController.text &&
            _newPasswordController.text.isNotEmpty;
    setState(() {
      _isMatching = isMatching; // _isMatching 값을 true 또는 false로 설정
    });
  }


  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    print(currentUser);
    if (currentUser != null) {
      try {
        // Set a timeout for the data loading process
        const timeout = Duration(seconds: 10);
        DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get()
            .timeout(timeout);

        print("Loaded user data: ${userDataSnapshot.data()}");
        setState(() {
          userData = UserData(
            name: userDataSnapshot['username'],
            email: currentUser.email ?? '',
            nickname: userDataSnapshot['nickname'],
            profileImgUrl: userDataSnapshot['profileImgUrl'],
            password: '',
          );
          isLoading = false;
        });
      } catch (e) {
        // Handle timeout or other errors
        print("Error loading user data: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경',
            style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.w700,)),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyAppPage()),
                    (Route<dynamic> route) => false,
              );
            },
          )
        ],
      ),

      body:  SingleChildScrollView(
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            Image.asset(
              'assets/image/logo.png', // Update the path accordingly
              height: 200, // Set the height of the image
            ),
            const SizedBox(height: 30),
            buildPasswordField("현재 비밀번호", "입력해주세요", _currentPasswordController),
            const SizedBox(height: 10),
            buildPasswordField("새 비밀번호", "입력해주세요", _newPasswordController),
            const SizedBox(height: 10),
            buildPasswordConfirmationField("새 비밀번호 확인", "입력해주세요"),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                if (_isMatching) {
                  performPasswordChange(_newPasswordController.text, context);
                } else {
                  // Show an error message indicating that passwords do not match
                  // You may want to display this message in a Snackbar or AlertDialog
                  print("Passwords do not match");
                }
                //로그인 화면으로 넘어가기
                goToAnotherPage(context, "LoginScreen");
              },
              child: const Text('비밀번호 변경', style: TextStyle(fontSize: 23,
                fontWeight: FontWeight.w700,)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

    )
    );
  }


  Widget buildPasswordField(String label, String hint, TextEditingController controller) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label,
              style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700,)
          )),
          const SizedBox(width: 10),
          Flexible(
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(hintText: hint,
                  hintStyle: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )
              ),
              controller: controller,
              onChanged: (_) {
                if (label == "새 비밀번호") {
                  checkPasswordMatch();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPasswordConfirmationField(String label, String hint) {
    return SizedBox(
      width: 300,
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label,
              style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700,)
          )),
          const SizedBox(width: 10),
          Flexible(
            child: TextField(
              obscureText: true,
              decoration: InputDecoration(hintText: hint,
                hintStyle: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              controller: _confirmationController,
              onChanged: (_) {
                checkPasswordMatch();
              },
            ),
          ),
          Builder(
            builder: (context) {
              if (_isMatching == true) {
                return const Icon(Icons.check, color: Colors.green);
              } else if (_isMatching == false) {
                return const Icon(Icons.close, color: Colors.red);
              } else {
                return const SizedBox(); // 아무것도 표시 X
              }
            },
          ),
        ],
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void performPasswordChange(String newPassword, BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        // Password updated successfully
        print("Password updated successfully");
      }
    } catch (e) {
      // Handle password change error
      print("Error changing password: $e");

      // Display an error message to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('비밀번호 변경 오류'),
            content: Text('비밀번호를 변경하는 중에 오류가 발생했습니다. 다시 시도해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }





}