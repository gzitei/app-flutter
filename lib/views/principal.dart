// ignore_for_file: prefer_typing_uninitialized_variables, sort_child_properties_last, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:collection';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:capital_especulativo_app/builder/date_picker.dart';
import 'package:capital_especulativo_app/builder/dialog_ok.dart';
import 'package:capital_especulativo_app/class/StockTransaction.dart';
import 'package:capital_especulativo_app/class/wallet.dart';
import 'package:capital_especulativo_app/controller/login_controller.dart';
import 'package:capital_especulativo_app/controller/transaction_controller.dart';
import 'package:capital_especulativo_app/controller/wallet_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../builder/campo_texto.dart';
import '../scripts/process_stocks.dart';
import '../scripts/stock_prices.dart';

TextEditingController transactionAmount = TextEditingController();
TextEditingController transactionDate = TextEditingController();
TextEditingController transactionTicker = TextEditingController();
TextEditingController transactionQtt = TextEditingController();
TextEditingController transactionType = TextEditingController();
TextEditingController transactionCarteiraId = TextEditingController();
TextEditingController transactionCarteiraName = TextEditingController();
var current_date;
var now = DateTime.now();
late var carteira, uid, usuario, nome, email, _future_carteira, transactions;
var visibility = [];
var _wallets = [];
var stocks = [];
var stock_info = {};
var summary;
var autor = AssetImage("lib/images/marx.png");
Future<dynamic> getWallet() async {
  uid = await FirebaseAuth.instance.currentUser!.uid;
  var _carteira = await WalletController().get(uid);
  return _carteira;
}

Future<Map<String, dynamic>> getData() async {
  return await LoginController().usuarioLogado();
}

dynamic getTransactions() async {
  uid = await FirebaseAuth.instance.currentUser!.uid;
  var transactions = await TransactionController().get(uid);
  if (transactions["ok"]) {
    List<Map<String, dynamic>> list = transactions["transactions"];
    return list;
  } else {
    return [];
  }
}

dynamic getStockInfos(list) async {}

const colorRed = Color.fromRGBO(166, 87, 75, 1);
const colorBlue = Color.fromRGBO(44, 55, 80, 1);

class PrincipalView extends StatefulWidget {
  const PrincipalView({super.key});

  @override
  State<PrincipalView> createState() => _PrincipalViewState();
}

class _PrincipalViewState extends State<PrincipalView>
    with SingleTickerProviderStateMixin {
  static const List<Tab> myTabs = <Tab>[
    Tab(
      icon: Icon(Icons.savings),
      text: "Carteira",
    ),
    Tab(
      icon: Icon(Icons.swap_horiz),
      text: "Aportes",
    ),
    // Tab(
    //   icon: Icon(Icons.ssid_chart_sharp),
    //   text: "Gráficos",
    // ),
  ];

  late TabController _tabController;

  @override
  void initState() {
    current_date = DateTime.now();
    usuario = getData();
    _future_carteira = getWallet();
    _tabController = TabController(
      vsync: this,
      length: myTabs.length,
    );
    transactions = getTransactions();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double largura = [
      380.toDouble(),
      (MediaQuery.of(context).size.width - 40).toDouble()
    ].reduce(min);
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            FutureBuilder(
              future: usuario,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var person = json.decode(json.encode(snapshot.data));
                  return SafeArea(
                    child: UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: colorRed,
                        border: Border(
                          bottom: BorderSide(
                            color: colorBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      margin: EdgeInsets.all(0),
                      accountName:
                          Text('${person["nome"]} ${person["sobrenome"]}'),
                      accountEmail: Text(person["email"]),
                    ),
                    top: true,
                  );
                }
                return CircularProgressIndicator();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person,
              ),
              title: Text("Minha conta"),
              onTap: () {
                Navigator.pushNamed(context, "conta");
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history,
              ),
              title: Text("Histórico de aportes"),
              onTap: () {
                Navigator.pushNamed(context, "transacoes");
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Sair"),
              onTap: () {
                LoginController().logout();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info,
              ),
              title: Text(
                "Sobre",
              ),
              onTap: () {
                dialog_ok(
                  context,
                  "Sobre o App",
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          height: 180,
                          width: 180,
                          child: Image(
                            image: autor,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                        Text(
                          "Este app foi criado por Gustavo Zitei Vicente para a disciplina de Programação para Dispositivos Móveis do curso de Análise e Desenvolvimento de Sistemas da Fatec de Ribeirão Preto.",
                          textAlign: TextAlign.justify,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: colorBlue,
        title: Text(
          "Meus investimentos",
          style: GoogleFonts.orelegaOne(fontSize: 28, letterSpacing: 2),
        ),
        toolbarHeight: 120,
        centerTitle: true,
        bottom: TabBar(
          indicatorPadding: EdgeInsets.all(5),
          indicatorColor: colorRed,
          indicatorWeight: 3,
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        children: [
          Container(
            height: 600,
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: colorRed,
                            fixedSize: Size.fromHeight(40)),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                var wallet_name = TextEditingController();
                                return AlertDialog(
                                  insetPadding: EdgeInsets.all(10),
                                  title: Text("Nome da Carteira"),
                                  content: Container(
                                    width: 300,
                                    padding: EdgeInsets.all(10),
                                    child: campoTexto(
                                      "Nome da Carteira",
                                      wallet_name,
                                      Icon(Icons.account_balance_wallet),
                                      16,
                                      false,
                                      TextInputType.name,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text(
                                        "Cancelar",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      onPressed: () => {Navigator.pop(context)},
                                    ),
                                    TextButton(
                                      child: const Text(
                                        "Criar",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      onPressed: () {
                                        if (wallet_name.text.isNotEmpty) {
                                          Navigator.pop(context);
                                          var agora = DateTime.now();
                                          var created_at =
                                              DateFormat.yMd("pt_BR")
                                                  .format(agora);
                                          var creation =
                                              agora.millisecondsSinceEpoch;
                                          var transactions = [];
                                          var id = null;
                                          var nome = wallet_name.text;
                                          Wallet(uid, created_at, creation,
                                              transactions, id, nome);
                                          try {
                                            WalletController().add(nome, uid);
                                            showPositiveFeedback(
                                                "Carteira criada!");
                                          } catch (e) {
                                            showNegativeFeedback(
                                                "Erro ao criar carteira!");
                                          }
                                          setState(() {
                                            _future_carteira = getWallet();
                                          });
                                        }
                                      },
                                    )
                                  ],
                                );
                              });
                        },
                        label: Text(
                          "Nova Carteira",
                          style: GoogleFonts.robotoSlab(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: FutureBuilder(
                    future: _future_carteira,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        carteira = snapshot.data!;
                        if (carteira["ok"]) {
                          _wallets = [];
                          carteira["wallets"].forEach((element) {
                            var element_id = element.id;
                            var elementJson =
                                element.data() as Map<String, dynamic>;
                            elementJson["id"] = element_id;
                            _wallets.add(Wallet.fromJson(elementJson));
                          });
                          if (_wallets.length > visibility.length) {
                            for (var i = visibility.length;
                                i < _wallets.length;
                                i++) {
                              visibility.add(false);
                            }
                          }
                          if (true) {
                            return ListView.builder(
                              itemCount: _wallets.length,
                              itemBuilder: (context, index) {
                                var current_wallet = _wallets[index] as Wallet;
                                return Column(
                                  children: [
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      margin: EdgeInsets.symmetric(vertical: 5),
                                      child: Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: colorBlue,
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          // gradient: LinearGradient(
                                          //     colors: [
                                          //       Colors.green,
                                          //       colorBlue
                                          //     ],
                                          //     begin: Alignment.bottomRight,
                                          //     end: Alignment.topCenter),
                                        ),
                                        child: Center(
                                          child: ListTile(
                                            onTap: () {
                                              setState(() {
                                                var atual = visibility[index];
                                                for (var i = 0;
                                                    i < visibility.length;
                                                    i++) {
                                                  visibility[i] = false;
                                                }
                                                if (!atual) {
                                                  visibility[index] = true;
                                                }
                                              });
                                            },
                                            title: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    _wallets[index].nome,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  // Text(
                                                  //   "45%",
                                                  //   style: TextStyle(
                                                  //       color: Colors.white),
                                                  // ),
                                                ]),
                                            leading: Icon(
                                              Icons.monetization_on_outlined,
                                              color: Colors.white,
                                            ),
                                            trailing: GestureDetector(
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                              onTap: () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                          title: Text(
                                                              "Deseja deletar?"),
                                                          content: Text(
                                                              "Não será possível desfazer sua ação."),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text(
                                                                "Cancelar",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16),
                                                              ),
                                                              onPressed: () => {
                                                                Navigator.pop(
                                                                    context)
                                                              },
                                                            ),
                                                            TextButton(
                                                              child: const Text(
                                                                "Confirmar",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                                setState(() {
                                                                  var _deleteWallet =
                                                                      _wallets[
                                                                          index];
                                                                  visibility
                                                                      .removeAt(
                                                                          index);
                                                                  try {
                                                                    WalletController().delete(
                                                                        _deleteWallet,
                                                                        context);
                                                                    showPositiveFeedback(
                                                                      "Carteira deletada!",
                                                                    );
                                                                  } catch (e) {
                                                                    showNegativeFeedback(
                                                                        "Erro ao deletar carteira.");
                                                                  }
                                                                  _future_carteira =
                                                                      WalletController()
                                                                          .get(
                                                                              uid);
                                                                });
                                                              },
                                                            )
                                                          ]);
                                                    });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    visibility[index] == false
                                        ? Container()
                                        : FutureBuilder(
                                            future: getTransactions(),
                                            builder: (context, snapshot) {
                                              var carteira_id =
                                                  _wallets[index].id;
                                              if (snapshot.hasData) {
                                                var dados = snapshot.data!
                                                    as List<
                                                        Map<String, dynamic>>;
                                                return FutureBuilder(
                                                  future: process_stocks(
                                                      carteira_id),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      print(snapshot.data!);
                                                      Map<String, dynamic>
                                                          snapshotdata =
                                                          json.decode(json
                                                              .encode(snapshot
                                                                  .data!));
                                                      if (snapshotdata
                                                          .entries.isEmpty) {
                                                        return Container();
                                                      }
                                                      var carteira_aberta =
                                                          snapshotdata[
                                                              current_wallet
                                                                  .id];
                                                      List<String> keys =
                                                          List.from(
                                                              carteira_aberta
                                                                  .keys);
                                                      return ListView.builder(
                                                        shrinkWrap: true,
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        itemCount: keys.length,
                                                        itemBuilder:
                                                            (context, pos) {
                                                          var this_stock =
                                                              keys[pos];
                                                          var stock_info =
                                                              carteira_aberta[
                                                                      this_stock]
                                                                  as Map<String,
                                                                      dynamic>;
                                                          print(stock_info);
                                                          return Card(
                                                            elevation: 2,
                                                            shadowColor:
                                                                Colors.black,
                                                            borderOnForeground:
                                                                true,
                                                            margin: EdgeInsets
                                                                .symmetric(
                                                                    vertical: 5,
                                                                    horizontal:
                                                                        5),
                                                            child: ListTile(
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8),
                                                              title: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    this_stock,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                  Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        "${NumberFormat.currency(locale: "pt_br", symbol: "R\$", decimalDigits: 2).format(stock_info["preco"])}",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                16),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            5,
                                                                      ),
                                                                      Text(
                                                                        "${NumberFormat.currency(locale: "pt_br", symbol: "R\$", decimalDigits: 2).format(stock_info["media"])}",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                12),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        "${NumberFormat.currency(locale: "pt_br", symbol: "R\$", decimalDigits: 2).format(stock_info["preco"] * stock_info["qtt"])}",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                16),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            5,
                                                                      ),
                                                                      Text(
                                                                        "${NumberFormat.currency(locale: "pt_br", symbol: "R\$", decimalDigits: 2).format(stock_info["media"] * stock_info["qtt"])}",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                12),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                              subtitle: Text(
                                                                  stock_info[
                                                                      "nome"]),
                                                              trailing: stock_info[
                                                                          "preco"] >=
                                                                      stock_info[
                                                                          "media"]
                                                                  ? Icon(
                                                                      Icons
                                                                          .arrow_circle_up,
                                                                      color: Colors
                                                                          .green,
                                                                    )
                                                                  : Icon(
                                                                      Icons
                                                                          .arrow_circle_down,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    }
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                                );
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                          )
                                  ],
                                );
                              },
                            );
                          }
                        } else {
                          return Container(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text("Crie uma carteira para começar!",
                                  style: GoogleFonts.robotoSlab(fontSize: 18)),
                            ),
                          );
                        }
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder(
            future: _future_carteira,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var local_carteira = snapshot.data! as Map<String, dynamic>;
                if (local_carteira["ok"]) {
                  List<DropdownMenuEntry> carteira_options = [];
                  local_carteira["wallets"].forEach((element) {
                    var carteira_id = element.id.toString();
                    var carteira_name = element.data()["nome"];
                    DropdownMenuEntry DropdownOption = DropdownMenuEntry(
                      label: carteira_name,
                      value: {"id": carteira_id, "name": carteira_name},
                      enabled: true,
                    );
                    carteira_options.add(DropdownOption);
                  });
                  return Container(
                    width: 400,
                    padding: EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            "Nova Transação",
                            style: GoogleFonts.orelegaOne(fontSize: 28),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            width: largura,
                            child: campoTexto(
                              "Ticker",
                              transactionTicker,
                              Icon(Icons.domain),
                              16,
                              false,
                              TextInputType.text,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: largura,
                            child: campoTexto(
                                "Valor total",
                                transactionAmount,
                                Icon(Icons.attach_money),
                                16,
                                false,
                                TextInputType.numberWithOptions(decimal: true)),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: largura,
                            child: seletorData(
                              "Data",
                              transactionDate,
                              Icon(Icons.calendar_month),
                              16,
                              context,
                              (value) {
                                if (value != null) {
                                  setState(
                                    () {
                                      current_date = value;
                                      transactionDate.text =
                                          DateFormat.yMd("pt_br").format(value);
                                    },
                                  );
                                }
                              },
                              current_date,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            child: DropdownMenu(
                              width: largura,
                              leadingIcon: Icon(Icons.account_balance_wallet),
                              onSelected: (value) {
                                setState(() {
                                  transactionCarteiraId.text = value["id"];
                                  transactionCarteiraName.text = value["name"];
                                });
                              },
                              textStyle: GoogleFonts.robotoSlab(fontSize: 14),
                              dropdownMenuEntries: carteira_options,
                              label: Text("Carteira"),
                              inputDecorationTheme: InputDecorationTheme(
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: largura,
                            child: campoTexto(
                              "Quantidade",
                              transactionQtt,
                              Icon(Icons.numbers),
                              16,
                              false,
                              TextInputType.text,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          DropdownMenu(
                            width: largura,
                            leadingIcon: Icon(Icons.swap_horiz),
                            onSelected: (value) {
                              setState(() {
                                transactionType.text = value!;
                              });
                            },
                            textStyle: GoogleFonts.robotoSlab(fontSize: 16),
                            dropdownMenuEntries: [
                              DropdownMenuEntry(
                                  value: "COMPRA", label: "Compra"),
                              DropdownMenuEntry(value: "VENDA", label: "Venda"),
                            ],
                            label: Text("Tipo"),
                            inputDecorationTheme: InputDecorationTheme(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            width: largura,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.price_check),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: colorRed,
                                  fixedSize: Size.fromHeight(60)),
                              onPressed: () {
                                if (transactionTicker.text.isEmpty) {
                                  showNegativeFeedback(
                                      "O campo Ticker é obrigatório!");
                                  return;
                                }
                                if (transactionAmount.text.isEmpty) {
                                  showNegativeFeedback(
                                      "O campo Valor total é obrigatório!");
                                  return;
                                }
                                if (transactionDate.text.isEmpty) {
                                  showNegativeFeedback(
                                      "O campo Data é obrigatório!");
                                  return;
                                }
                                if (transactionCarteiraId
                                    .value.isUndefinedOrNull) {
                                  showNegativeFeedback(
                                      "O campo Carteira é obrigatório!");
                                  return;
                                }
                                if (transactionQtt.text.isEmpty) {
                                  showNegativeFeedback(
                                      "O campo Quantidade é obrigatório!");
                                  return;
                                }
                                if (transactionType.value.isUndefinedOrNull) {
                                  showNegativeFeedback(
                                      "O campo Tipo é obrigatório!");
                                  return;
                                }
                                var date = DateFormat.yMd("pt_BR")
                                    .parse(transactionDate.text);
                                var ticker =
                                    transactionTicker.text.toUpperCase();
                                var type = transactionType.text;
                                var created_at = transactionDate.text;
                                var creation = date.millisecondsSinceEpoch;
                                var quantity, amount;
                                var tickerOk = RegExp(r"^[A-Z]{4}[0-9]{1,2}$")
                                    .hasMatch(ticker);
                                if (tickerOk == false) {
                                  showNegativeFeedback(
                                      "Ticker: formato inválido!");
                                  return;
                                }
                                try {
                                  quantity = NumberFormat("pt_BR")
                                      .parse(transactionQtt.text);
                                } catch (e) {
                                  showNegativeFeedback(
                                      "Quantidade: formato inválido!");
                                  return;
                                }
                                try {
                                  amount = NumberFormat("pt_BR")
                                      .parse(transactionAmount.text);
                                } catch (e) {
                                  showNegativeFeedback(
                                      "V1alor total: formato inválido!");
                                  return;
                                }
                                var wallet_id =
                                    transactionCarteiraId.text.toString();
                                var wallet_name = transactionCarteiraName.text;
                                StockTransaction transacao = StockTransaction(
                                  ticker,
                                  uid,
                                  type,
                                  created_at,
                                  creation,
                                  quantity,
                                  amount,
                                  wallet_id,
                                  null,
                                  wallet_name,
                                );
                                try {
                                  TransactionController().add(transacao);
                                  showPositiveFeedback("Transação adicionada!");
                                  setState(() {
                                    transactionAmount.clear();
                                    transactionDate.clear();
                                    transactionQtt.clear();
                                    transactionTicker.clear();
                                    transactionCarteiraId.clear();
                                    transactionCarteiraName.clear();
                                    transactionType.clear();
                                    _tabController.index = 0;
                                  });
                                } catch (e) {
                                  showNegativeFeedback(
                                      "Erro ao adicionar transação.");
                                }
                              },
                              label: Text(
                                "Salvar",
                                style: GoogleFonts.robotoSlab(fontSize: 18),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text("Crie uma carteira para começar!",
                          style: GoogleFonts.robotoSlab(fontSize: 18)),
                    ),
                  );
                }
              }
              return CircularProgressIndicator();
            },
          ),
        ],
        controller: _tabController,
      ),
    );
  }

  dynamic showPositiveFeedback(String? msg) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        closeIconColor: Colors.white,
        width: MediaQuery.of(context).size.width - 50,
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
        content: Center(
            child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 25,
                width: 25,
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 20,
                  ),
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                msg.isUndefinedOrNull ? "Sucesso!" : msg!,
                style: GoogleFonts.robotoSlab(fontSize: 14),
              ),
            ],
          ),
        )),
      ),
    );
  }

  dynamic showNegativeFeedback(String? msg) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        closeIconColor: Colors.white,
        width: MediaQuery.of(context).size.width - 50,
        showCloseIcon: true,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
        content: Center(
            child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 25,
                width: 25,
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: 20,
                  ),
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                msg.isUndefinedOrNull ? "Tente novamente!" : msg!,
                style: GoogleFonts.robotoSlab(fontSize: 14),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
