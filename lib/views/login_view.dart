import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/services/authentication_service.dart';
import 'package:auto_glass_crm/views/home_page.dart';
import 'package:auto_glass_crm/views/password_reset.dart';
import 'package:auto_glass_crm/views/signup_view.dart';
import 'package:auto_glass_crm/models/authentication_response.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {

  LoginView();

  @override
  _LoginViewState createState() => new _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  BuildContext _scaffoldContext;
  TextEditingController _emailController = new TextEditingController(text: "");
  TextEditingController _pwController = new TextEditingController(text: "");
  final FocusNode myFocusNode = FocusNode();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isAuthenticating = false;
  bool bRememberMe = true;

  @override
  void initState() {
    super.initState();
  }

  void doLogin() async {
    var email = _emailController.text.trim();
    var password = _pwController.text.trim();
    var urlPrefix;
    urlPrefix = await AuthenticationService.getPrefixByEmail(email);
    if ( urlPrefix == null ){
      var err = "We're sorry, the email you entered is not associated with any AutoGlassCRM account.";
      final snackBar = SnackBar(
        content: Text(err),
      );
      Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
      isAuthenticating = false;
      setState(() {});

      return;
    }


    var response = await AuthenticationService.authenticate(urlPrefix, email, password);
    if (response != null && response.token != null && (response.error == null || response.error == "") ) {
      Global.currentUserName = _emailController.text.trim();
      Global.currentPassword = _pwController.text.trim();
      Global.domainPrefix = urlPrefix;
      Global.userID = response.id;
      Global.userFirstName = response.first_name;
      Global.userLastName =response.last_name;
      Global.userToken = response.token;
      Global.userAccess = response.access;
      Global.vindecoderAuth = response.vindecoderAuth;
      Global.vindecoderOnly = response.vindecoderOnly;
      Global.country = response.country;
      Global.isRemeberMe = bRememberMe;
      Global.notificationStatus = "1";
      Global.saveSettings();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => HomePage(),
        ),
      );
    } else {
      var err = 'An error occurred. Please check your username & password and try again.';

      if ( response != null && response.error != null && response.error != "" ){
        err = response.error;
      }

      final snackBar = SnackBar(
        content: Text(err),
      );
      Scaffold.of(_scaffoldContext).showSnackBar(snackBar);

      isAuthenticating = false;
      setState(() {});
    }
  }

  _loadingWidget() {
    return SizedBox(
      height: 25.0,
      width: 25.0,
      child: new CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEFEFEF)),
        value: null,
        strokeWidth: 7.0,
      ),
    );
  }

  _signinTextWidget() {
    return Text(
      "Sign In",
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFF1E3C6B),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E3C6B),
        title: Image.asset("assets/logo_sm.png"),
        centerTitle: true,
      ),
      body: Builder(builder: (BuildContext context) {
        _scaffoldContext = context;
        return GestureDetector(
          onTap: () => FocusScope.of(context)
              .requestFocus(new FocusNode()), // hide keyboard
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  padding: EdgeInsets.only(top: 0.0, bottom: 10.0, left: 25),
                  margin: const EdgeInsets.only(top: 20.0),
                ),
                SizedBox(height: 24.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0),
                  ),
                  margin: const EdgeInsets.symmetric(
                      vertical: 0.0, horizontal: 20.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: 5, right: 38, top: 10, bottom: 10),
                        child: Text(
                          "Email",
                          style: TextStyle(
                            color: Color(0xFFA4C6EB),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          autocorrect: false,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          onSubmitted: (newValue) {
                            FocusScope.of(context).requestFocus(myFocusNode);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Divider(
                    color: Colors.grey,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0),
                  ),
                  margin: const EdgeInsets.symmetric(
                      vertical: 0.0, horizontal: 20.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top:10, bottom: 10, left: 5, right:7),
                        child: Text(
                          "Password",
                          style: TextStyle(
                            color: Color(0xFFA4C6EB),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          autocorrect: false,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          keyboardType: TextInputType.text,
                          controller: _pwController,
                          obscureText: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          focusNode: myFocusNode,
                          onSubmitted: (newValue) {
                            isAuthenticating = true;
                            setState(() {});
                            doLogin();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Divider(
                    color: Colors.grey,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.only(left: 10.0, right: 20.0),
                  child: CheckboxListTile(
                    title: Text("Remember me", style: TextStyle(
                      color: Color(0xFFA4C6EB)
                    ),),
                    value: bRememberMe,
                    onChanged: (bool value) {
                      setState(() {
                        bRememberMe = value;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  )
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20.0),
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MaterialButton(
                            color: Color(0xFF027BFF),
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: isAuthenticating
                                  ? _loadingWidget()
                                  : _signinTextWidget(),
                            ),
                            onPressed: () {
                              if (isAuthenticating) {
                                return null;
                              } else {
                                isAuthenticating = true;
                                setState(() {});
                                doLogin();
                              }
                            }),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  child: Center(
                    child: new GestureDetector(
                      child: Text("Password Reset",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline
                        ),
                      ),
                      onTap: (){
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => PasswordResetView()
                          )
                        );
                      },
                    )
                  )
                ),

                /*
                Container(
                    margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "New to AutoGlassCRM?",
                            style: TextStyle(
                              color: Color(0xFFA4C6EB),
                              fontSize: 12,
                            ),
                          ),

                          new GestureDetector(
                            onTap: (){
                              Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (BuildContext context) => SignupView()
                                  )
                              );
                            },
                            child: Text(
                              " Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                        ]
                    )
                ),
                */
              ],
            ),
          ),
        );
      }),
    );
  }
}
