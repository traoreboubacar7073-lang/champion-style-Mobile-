import 'package:flutter/material.dart';

/// Observateur de navigation global — permet à un écran de savoir quand
/// on revient dessus après avoir fermé un écran ouvert par-dessus (ex :
/// tableau de bord -> "Voir tout" -> retour), pour qu'il recharge ses
/// données à jour au lieu de garder celles qu'il avait à l'ouverture.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
