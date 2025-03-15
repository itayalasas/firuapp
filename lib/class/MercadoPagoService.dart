import 'package:mercadopago_sdk/mercadopago_sdk.dart';

class MercadoPagoService {
  final String accessToken;

  MercadoPagoService(this.accessToken);

  Future<Map<String, dynamic>> createPreference({
    required String title,
    required double price,
    required int quantity,
    required String description,
  }) async {
    MP mp = MP.fromAccessToken(accessToken);

    var preference = {
      "items": [
        {
          "title": title,
          "quantity": quantity,
          "currency_id": "UYU",
          "unit_price": price,
          "description": description,
        }
      ]
    };

    var result = await mp.createPreference(preference);
    return result;
  }
}
