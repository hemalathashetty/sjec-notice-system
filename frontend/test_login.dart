import 'package:dio/dio.dart';
void main() async {
  try {
    final dio = Dio();
    final response = await dio.post('http://127.0.0.1:8000/auth/login', data: {'email': 'superadmin@sjec.ac.in', 'password': 'password123'});
    print(response.data);
  } on DioException catch(e) {
    print('DioError: ${e.response?.data}');
  }
}
