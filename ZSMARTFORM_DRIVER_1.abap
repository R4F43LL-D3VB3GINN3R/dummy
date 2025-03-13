*&---------------------------------------------------------------------*
*& Report ZSMARTFORM_DRIVER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsmartform_driver_1.

"smartform name
DATA: fname TYPE tdsfname .
fname = 'ZSF_ORDER_28_1'.

"function smartform name
DATA: fname_output TYPE rs38l_fnam.

"pedido de compras
DATA: ls_order TYPE zstr_hdr_data.

"items de compras
DATA: it_items TYPE ztstr_item_data,
      ls_items TYPE zstr_item_data.

"tela de selecao
SELECTION-SCREEN: BEGIN OF BLOCK a1 WITH FRAME.
PARAMETERS: p_ebeln TYPE ekko-ebeln.
SELECTION-SCREEN: END OF BLOCK a1.

"processamento

START-OF-SELECTION.

  PERFORM get_data.   "recolhe os dados necessarios
  PERFORM print_form. "impressao de documento smartform

END-OF-SELECTION.

FORM get_data.

  PERFORM get_order. "consulta por ordens de compras
  PERFORM get_items. "consulta por items de compras

ENDFORM.

FORM get_order.

  "consulta por pedido de compras
  SELECT SINGLE ebeln,
                aedat,
                ekgrp,
                lifnr,
                bsart
    FROM ekko
    INTO CORRESPONDING FIELDS OF @ls_order
  WHERE ebeln EQ @p_ebeln.

ENDFORM.

FORM get_items.

  "consulta por itens de compras
  IF ls_order IS NOT INITIAL.
    SELECT ebelp,
           txz01,
           peinh
      FROM ekpo
      INTO CORRESPONDING FIELDS OF TABLE @it_items
    WHERE ebeln EQ @p_ebeln.
  ENDIF.

ENDFORM.

FORM print_form.

  "funcao para buscar o nome da funcao que invoca o smartform
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = fname
*     VARIANT            = ' '
*     DIRECT_CALL        = ' '
    IMPORTING
      fm_name            = fname_output
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
    MESSAGE | O módulo de função não pode ser encontrador | TYPE 'I'.
    RETURN.
  ENDIF.

  "funcao para invocar o smartform a partir do nome da sua funcao
  CALL FUNCTION fname_output
    EXPORTING
*     ARCHIVE_INDEX    =
*     ARCHIVE_INDEX_TAB          =
*     ARCHIVE_PARAMETERS         =
*     CONTROL_PARAMETERS         =
*     MAIL_APPL_OBJ    =
*     MAIL_RECIPIENT   =
*     MAIL_SENDER      =
*     OUTPUT_OPTIONS   =
*     USER_SETTINGS    = 'X'
      order            = ls_order "estrutura de pedidos
      items            = it_items "estrutura de items de compras
      item             = ls_items "tabela com os itens de compras
*   IMPORTING
*     DOCUMENT_OUTPUT_INFO       =
*     JOB_OUTPUT_INFO  =
*     JOB_OUTPUT_OPTIONS         =
    EXCEPTIONS
      formatting_error = 1
      internal_error   = 2
      send_error       = 3
      user_canceled    = 4
      OTHERS           = 5.
  IF sy-subrc <> 0.
    MESSAGE | Não foi possível imprimir o relatório smartforms | TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.
