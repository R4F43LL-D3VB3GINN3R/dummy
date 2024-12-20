CLASS zcl_ckf_orders DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA mt_orders TYPE zckf_orders_tt .
    DATA ms_order TYPE zckf_orders_st .
    DATA ms_result TYPE zckf_msg_st .

    METHODS construtor
      IMPORTING
        !po_key TYPE ebeln OPTIONAL.
    CLASS-METHODS factory
      IMPORTING
        !po_key   TYPE ebeln OPTIONAL
      EXPORTING
        !ol_order TYPE REF TO zcl_ckf_orders.
    METHODS get_order
      IMPORTING
        !po_key TYPE ebeln.
  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS get_orders_to_release .
ENDCLASS.

CLASS ZCL_CKF_ORDERS IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CKF_ORDERS->CONSTRUTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] PO_KEY                         TYPE        EBELN(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD construtor.

    "se a chave nao for enviada
    IF po_key IS INITIAL.
      "invoca o método private responsável por consulta à base de dados
      me->get_orders_to_release( ).
      "se enviarem a chave
    ELSE.
      me->get_order( po_key = po_key ).
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_CKF_ORDERS=>FACTORY
* +-------------------------------------------------------------------------------------------------+
* | [--->] PO_KEY                         TYPE        EBELN(optional)
* | [<---] OL_ORDER                       TYPE REF TO ZCL_CKF_ORDERS
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD factory.

    CREATE OBJECT ol_order.

    "se nao for enviada a chave
    IF po_key IS INITIAL.
      ol_order->construtor( ).
      "se a chave for enviada.
    ELSE.
      ol_order->construtor( po_key = po_key ).
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_CKF_ORDERS->GET_ORDER
* +-------------------------------------------------------------------------------------------------+
* | [--->] PO_KEY                         TYPE        EBELN
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_order.

    "procura por pedidos de compras pendentes
    me->get_orders_to_release( ).

    "procura o pedido de compra com a chave enviada
    READ TABLE me->mt_orders INTO DATA(ls_data) WITH KEY ebeln = po_key.

    IF sy-subrc EQ 0.
      me->ms_order = ls_data. "estrutura da classe recebe a ordem de compra
    ELSE.
      me->ms_result-rc      = sy-subrc.
      me->ms_result-message = | 'Não foi encontrada uma Ordem de Compra com a chave pretendida' |.
      me->ms_result-objid   = po_key.
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method ZCL_CKF_ORDERS->GET_ORDERS_TO_RELEASE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_orders_to_release.

    "limpa o atributo tabela de ordens
    CLEAR me->mt_orders.

    "consulta para buscar ordens de pedidos de compras
    SELECT ebeln, "Purchasing Document Number
           ekgrp, "Purchasing Group
           lifnr, "Vendor's account number
           bsart, "Order Type (Purchasing)
           aedat FROM ekko INTO TABLE @me->mt_orders
     WHERE frgrl EQ 'X'.

  ENDMETHOD.
ENDCLASS.
