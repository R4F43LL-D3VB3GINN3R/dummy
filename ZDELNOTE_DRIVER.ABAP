*&---------------------------------------------------------------------*
*& Report ZDELNOTE_DRIVER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

"PROGRAMA STANDARD PARA TESTES -> RSTXSCRP

REPORT zdelnote_driver.

TABLES: lips, likp, tvko, adrc  .

"---------

"SD Document: Delivery Header Data
TYPES: BEGIN OF ty_likp,
         vbeln TYPE likp-vbeln, "Delivery
         vstel TYPE likp-vstel, "Shipping Point/Receiving Point
         lfdat TYPE likp-lfdat, "Delivery Date
         inco1 TYPE likp-inco1, "Incoterms (Part 1)
       END OF ty_likp.

DATA: slikp TYPE ty_likp.

"---------

"SD document: Delivery: Item data
TYPES: BEGIN OF ty_lips,
         matnr TYPE lips-matnr,  " Código do material
         arktx TYPE lips-arktx,  " Descrição do material
         lfimg TYPE lips-lfimg,  " Quantidade
         meins TYPE lips-meins,  " Unidade de medida
         ntgew TYPE lips-ntgew,  " Peso líquido
       END OF ty_lips.

DATA: lt_lips TYPE TABLE OF lips,
      wa_lips TYPE lips.

"---------

"Organizational Unit: Sales Organizations
TYPES: BEGIN OF ty_tvko,
         vkorg     TYPE tvko-vkorg,
         txnam_adr TYPE tvko-txnam_adr,
       END OF ty_tvko.

DATA: lt_tvko TYPE TABLE OF tvko,
      wa_tvko TYPE tvko.

"---------

DATA: count TYPE n LENGTH 3.
DATA: str_lfimg TYPE c LENGTH 5.
DATA: new(3) TYPE n.
DATA: temp TYPE p DECIMALS 1.
DATA: temp1(5) TYPE c.

"Addresses (Business Address Services)
TYPES: BEGIN OF ty_adrc,
         name1      TYPE adrc-name1,      " Name 1
         city1      TYPE adrc-city1,      " City
         street     TYPE adrc-street,     " Street
         country    TYPE adrc-country,    " Country Key
         po_box     TYPE adrc-po_box,     " PO Box
         tel_number TYPE adrc-tel_number, " First telephone no.: dialling code+number
       END OF ty_adrc.

DATA: wa_adrc  TYPE adrc,
      wa_adrc2 TYPE adrc.

"---------

SELECTION-SCREEN: BEGIN OF BLOCK a1 WITH FRAME.
PARAMETERS: p_vbeln TYPE likp-vbeln DEFAULT '80000001'.
SELECTION-SCREEN: END OF BLOCK a1.

START-OF-SELECTION.
  PERFORM get_data.
  PERFORM print_data.


FORM get_data.

  "get data from delivery doc header
  PERFORM get_likp.
  "get the sales org address.
  PERFORM get_tvko.
  "get sales org address and "get sold to party address.
  PERFORM get_adrcs.
  "get items.
  PERFORM get_lips.

ENDFORM.

FORM print_data.

  "call formulary
  PERFORM open_form.
  "get sales address window
  PERFORM print_form_address.
  "get sold address window
  PERFORM print_form_address2.
  "get delivery point window
  PERFORM print_form_details.
  "get col_head window
  PERFORM print_item_details.
  "close opened formulary
  PERFORM close_form.

ENDFORM.

FORM get_likp.

  slikp-vbeln = '80000001'. " Número do documento de entrega
  slikp-vstel = '1000'.     " Ponto de expedição/receptora
  slikp-lfdat = '20240301'. " Data da entrega (formato AAAAMMDD)
  slikp-inco1 = 'EXW'.      " Incoterms (exemplo: EXW - Ex Works)

ENDFORM.

FORM get_tvko.

  wa_tvko-vkorg = '1000'.
  wa_tvko-txnam_adr = 'Dummy Address'.
  APPEND wa_tvko TO lt_tvko.

ENDFORM.

FORM get_adrcs.

  wa_adrc-name1      = 'SBXS Sales Company'. " Nome
  wa_adrc-city1      = 'Porto'.              " Cidade
  wa_adrc-street     = 'Dummy St 100'.       " Rua
  wa_adrc-country    = 'PT'.                 " País (Portugal)
  wa_adrc-po_box     = '1000'.               " Caixa Postal
  wa_adrc-tel_number = '912345678'.          " Número de telefone

  wa_adrc2-name1      = 'SAP'.                " Nome
  wa_adrc2-city1      = 'Walldorf'.           " Cidade
  wa_adrc2-street     = 'Dummy St 200'.       " Rua
  wa_adrc2-country    = 'DE'.                 " País (Portugal)
  wa_adrc2-po_box     = '69190'.              " Caixa Postal
  wa_adrc2-tel_number = '+49 170 1234567'.    " Número de telefone

ENDFORM.

FORM get_lips.

  wa_lips-matnr = 'MAT004'.
  wa_lips-arktx = 'Product D'.
  wa_lips-lfimg = '3'.
  wa_lips-meins = 'KG'.
  wa_lips-ntgew = '7'.
  APPEND wa_lips TO lt_lips.

  wa_lips-matnr = 'MAT005'.
  wa_lips-arktx = 'Product E'.
  wa_lips-lfimg = '5'.
  wa_lips-meins = 'KG'.
  wa_lips-ntgew = '12'.
  APPEND wa_lips TO lt_lips.

  wa_lips-matnr = 'MAT006'.
  wa_lips-arktx = 'Product F'.
  wa_lips-lfimg = '2'.
  wa_lips-meins = 'KG'.
  wa_lips-ntgew = '4'.
  APPEND wa_lips TO lt_lips.

  wa_lips-matnr = 'MAT007'.
  wa_lips-arktx = 'Product G'.
  wa_lips-lfimg = '1'.
  wa_lips-meins = 'KG'.
  wa_lips-ntgew = '1'.
  APPEND wa_lips TO lt_lips.

  wa_lips-matnr = 'MAT008'.
  wa_lips-arktx = 'Product H'.
  wa_lips-lfimg = '9'.
  wa_lips-meins = 'KG'.
  wa_lips-ntgew = '20'.
  APPEND wa_lips TO lt_lips.

  wa_lips-matnr = 'MAT009'.
  wa_lips-arktx = 'Product I'.
  wa_lips-lfimg = '7'.
  wa_lips-meins = 'KG'.
  wa_lips-ntgew = '14'.
  APPEND wa_lips TO lt_lips.


ENDFORM.

FORM open_form.

  CALL FUNCTION 'OPEN_FORM'
    EXPORTING
*     APPLICATION                 = 'TX'
*     ARCHIVE_INDEX               =
*     ARCHIVE_PARAMS              =
      device                      = 'PRINTER'
*     DIALOG                      = 'X'
      form                        = 'ZDELNOTE'
      language                    = sy-langu
*     OPTIONS                     =
*     MAIL_SENDER                 =
*     MAIL_RECIPIENT              =
*     MAIL_APPL_OBJECT            =
*     RAW_DATA_INTERFACE          = '*'
*     SPONUMIV                    =
*   IMPORTING
*     LANGUAGE                    =
*     NEW_ARCHIVE_PARAMS          =
*     RESULT                      =
    EXCEPTIONS
      canceled                    = 1
      device                      = 2
      form                        = 3
      options                     = 4
      unclosed                    = 5
      mail_options                = 6
      archive_error               = 7
      invalid_fax_number          = 8
      more_params_needed_in_batch = 9
      spool_error                 = 10
      codepage                    = 11
      OTHERS                      = 12.

  IF sy-subrc <> 0.
    MESSAGE | Error to open formulary | TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.

FORM print_form_address.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'SALES'
*     FUNCTION                 = 'SET'
*     TYPE                     = 'BODY'
      window                   = 'ADD1'
* IMPORTING
*     PENDING_LINES            =
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.

  IF sy-subrc <> 0.
    MESSAGE | Error to show sales address | TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.

FORM print_form_address2.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'SOLD'
*     FUNCTION                 = 'SET'
*     TYPE                     = 'BODY'
      window                   = 'ADD2'
* IMPORTING
*     PENDING_LINES            =
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.

  IF sy-subrc <> 0.
    MESSAGE | Error to show sold address | TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.

FORM print_form_details.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'DETAILS'
*     FUNCTION                 = 'SET'
*     TYPE                     = 'BODY'
      window                   = 'DETAILS'
* IMPORTING
*     PENDING_LINES            =
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.

  IF sy-subrc <> 0.
    MESSAGE | Error to show sold address | TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.

FORM print_item_details.

  count = '1'.

  LOOP AT lt_lips INTO wa_lips.

    CONDENSE count NO-GAPS.
    CONDENSE wa_lips-arktx NO-GAPS.
    str_lfimg = wa_lips-lfimg.
    CONDENSE str_lfimg NO-GAPS.

    CALL FUNCTION 'WRITE_FORM'
      EXPORTING
        element                  = 'ITEM'
*       FUNCTION                 = 'SET'
*       TYPE                     = 'BODY'
        window                   = 'MAIN'
* IMPORTING
*       PENDING_LINES            =
      EXCEPTIONS
        element                  = 1
        function                 = 2
        type                     = 3
        unopened                 = 4
        unstarted                = 5
        window                   = 6
        bad_pageformat_for_print = 7
        spool_error              = 8
        codepage                 = 9
        OTHERS                   = 10.

    count = count + 1.

    WHILE count GT 2.
      count = count / 2.
    ENDWHILE.

*    temp = count / 2.
*    temp1 = temp.
*    SPLIT temp1 AT '.' INTO temp1 new.
*    CONDENSE temp1 NO-GAPS.

  ENDLOOP.

  IF sy-subrc <> 0.
    MESSAGE | Error to show items information | TYPE 'I'.
    RETURN.
  ENDIF.

ENDFORM.

FORM close_form.

  CALL FUNCTION 'CLOSE_FORM'
*   IMPORTING
*     RESULT                         =
*     RDI_RESULT                     =
*   TABLES
*     OTFDATA                        =
    EXCEPTIONS
      unopened                 = 1
      bad_pageformat_for_print = 2
      send_error               = 3
      spool_error              = 4
      codepage                 = 5
      OTHERS                   = 6.
  IF sy-subrc <> 0.
    IF sy-subrc <> 0.
      MESSAGE | Error to close formulary | TYPE 'I'.
      RETURN.
    ENDIF.
  ENDIF.

ENDFORM.
