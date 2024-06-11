
import 'package:flutter/material.dart';


class CustomFormfield extends StatelessWidget {
  final String hintText;
  final double height;
  final RegExp validateRegEx;
  final bool obscureText;
  final void Function(String?) onSaved;


  const CustomFormfield({
    super.key,
    required this.hintText,
    required this.height,
    required this.validateRegEx,
    this.obscureText=false,
    required this.onSaved
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        obscureText: obscureText,
        onSaved: onSaved,
        validator:(value) {
          if(value!=null && validateRegEx.hasMatch(value)){
            return null;
          }
          return "Enter a valid ${hintText.toLowerCase()}";
        },
        //autovalidateMode: AutovalidateMode.disabled,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: hintText,
        ),
      ),
    );
  }
}