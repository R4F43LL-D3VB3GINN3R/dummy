*&---------------------------------------------------------------------*
*& Report ZSMARTFORMS_SBX
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsmartforms_sbx.

TABLES: t001, "Empresas.
        bkpf, "Cabeçalho do documento contábil
        bseg. "Segmento do documento contabilidade financeira

"primeira parte
DATA: it_empresas     TYPE zempresa_tt,
      ls_empresa      TYPE zempresa_st,
      it_empresas_fat TYPE TABLE OF bkpf,
      ls_empresa_fat  TYPE bkpf.

"segunda parte
DATA: it_clientes     TYPE zempresa_tt,
      ls_cliente      TYPE zempresa_st,
      it_clientes_fat TYPE TABLE OF bseg,
      ls_cliente_fat  TYPE bseg.

"documentos de Fatura
DATA: it_faturas TYPE TABLE OF bkpf,
      ls_fatura  TYPE bkpf.

"itens da fatura
DATA: it_seg_fatura TYPE zseg_fatura_tt,
      ls_seg_fatura TYPE zseg_fatura_st.

"saldo total.
DATA: total_saldo     TYPE wrbtr,
      total_str_saldo TYPE string.

"listboxes
DATA: it_listbox_empresas TYPE vrm_values,
      ls_listbox_empresa  LIKE LINE OF it_listbox_empresas.
DATA: it_listbox_clientes TYPE vrm_values,
      ls_listbox_cliente  LIKE LINE OF it_listbox_clientes.
DATA: it_listbox_faturas TYPE vrm_values,
      ls_listbox_fatura  LIKE LINE OF it_listbox_faturas.

CONSTANTS: fname TYPE tdsfname VALUE 'ZSF_SBX001'.

"nome da funcao que invoca o smartform
DATA: fname_output TYPE rs38l_fnam.

SELECTION-SCREEN: BEGIN OF BLOCK a1 WITH FRAME.
PARAMETERS: p_bukrs  TYPE t001-bukrs AS LISTBOX VISIBLE LENGTH 20 DEFAULT 'PT03',
            p_fatura TYPE bseg-belnr AS LISTBOX VISIBLE LENGTH 20,
            p_bukrs2 TYPE t001-bukrs AS LISTBOX VISIBLE LENGTH 20.
SELECTION-SCREEN: END OF BLOCK a1.

AT SELECTION-SCREEN OUTPUT.
  SET PF-STATUS 'ZGUI_FORMS'.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'BACK'.
      LEAVE PROGRAM.
    WHEN 'DISPLAY'.
      PERFORM prepare_data.
      PERFORM prepare_items_fatura.
      PERFORM generate_qrcode.
      PERFORM display_data.
    WHEN OTHERS.
      IF p_fatura IS INITIAL.
        PERFORM get_faturas.
        PERFORM fill_listbox_faturas.
      ELSE.
        PERFORM get_clientes.
        PERFORM fill_listbox_cliente.
      ENDIF.
  ENDCASE.

INITIALIZATION.

  PERFORM get_empresas.
  PERFORM fill_listbox_empresa.

FORM display_data.

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
      st_empresa       = ls_empresa
      st_empresa2      = ls_cliente
      st_fatura        = ls_fatura
      tt_seg_fatura    = it_seg_fatura
      lv_total         = total_str_saldo
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

*  cl_demo_output=>display( ls_empresa ).

ENDFORM.

FORM get_empresas.

  "seleciona empresas em que haja trâmite de fatura
  SELECT * FROM bkpf INTO TABLE it_empresas_fat.

  "busca as informacoes destas empresas
  SELECT * FROM t001 INTO CORRESPONDING FIELDS OF TABLE @it_empresas
  FOR ALL ENTRIES IN @it_empresas_fat
  WHERE bukrs EQ @it_empresas_fat-bukrs.

ENDFORM.

FORM get_faturas.

  "seleciona todas as faturas com clientes
  SELECT * FROM bkpf
    INNER JOIN bseg
    ON bseg~belnr EQ bkpf~belnr
    INTO CORRESPONDING FIELDS OF TABLE @it_faturas
    WHERE bkpf~bukrs EQ @p_bukrs
    AND bseg~kunnr NE ' '.

ENDFORM.

FORM get_clientes.

  "consulta o numero do cliente pelo numero da fatura
  SELECT SINGLE kunnr FROM bseg INTO @DATA(temp_kunnr) WHERE belnr EQ @p_fatura.

  "consulta o codigo da empresa do cliente
  SELECT SINGLE bukrs FROM knb1 INTO @DATA(temp_bukrs) WHERE kunnr EQ @temp_kunnr.

  "consulta as informacoes da empresa do cliente
  SELECT SINGLE * FROM t001 INTO CORRESPONDING FIELDS OF ls_cliente WHERE bukrs EQ temp_bukrs.

ENDFORM.

FORM prepare_data.

  CLEAR: ls_empresa, ls_cliente.

  "busca as informacoes da empresa
  SELECT SINGLE * FROM t001 INTO CORRESPONDING FIELDS OF ls_empresa WHERE bukrs EQ p_bukrs.

  "busca as informacoes da empresa do cliente
  SELECT SINGLE * FROM t001 INTO CORRESPONDING FIELDS OF ls_cliente WHERE bukrs EQ p_bukrs2.

  "trata email
  CONCATENATE  'sender@companyname' ls_empresa-land1 INTO ls_empresa-email SEPARATED BY '.'.
  CONDENSE ls_empresa-email NO-GAPS.
  "trata email
  CONCATENATE  'sender@companyname' ls_cliente-land1 INTO ls_cliente-email SEPARATED BY '.'.
  CONDENSE ls_cliente-email NO-GAPS.

  "trata endereço
  ls_empresa-address  = 'Defaultstreet N 000 St'.
  ls_cliente-address  = 'Defaultstreet N 000 St'.

ENDFORM.

FORM prepare_items_fatura.

  "consulta por todos os items da fatura.
  SELECT * FROM bseg
    INTO TABLE  @DATA(temp_segfat)
    WHERE belnr EQ @p_fatura.

  "procedimento para remover espaços dos valores decimais
  LOOP AT temp_segfat INTO DATA(st_datafat).
    MOVE-CORRESPONDING st_datafat TO ls_seg_fatura.
    CONDENSE ls_seg_fatura-wrbtr NO-GAPS.

    "trata o saldo total dos valores
    total_saldo     = total_saldo + ls_seg_fatura-wrbtr.
    total_str_saldo = total_saldo.
    CONDENSE total_str_saldo NO-GAPS.

    APPEND ls_seg_fatura TO it_seg_fatura.
    CLEAR ls_seg_fatura.
    CLEAR st_datafat.
  ENDLOOP.

ENDFORM.

FORM generate_qrcode.



ENDFORM.

FORM fill_listbox_empresa.

  LOOP AT it_empresas INTO ls_empresa.
    ls_listbox_empresa-key  = ls_empresa-bukrs.
    ls_listbox_empresa-text = ls_empresa-butxt.
    APPEND ls_listbox_empresa TO it_listbox_empresas.
    CLEAR: ls_listbox_empresa, ls_empresa.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_BUKRS'
      values = it_listbox_empresas.

ENDFORM.

FORM fill_listbox_cliente.

  CLEAR: it_clientes, it_listbox_clientes.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_BUKRS2'
      values = it_listbox_clientes.

  ls_listbox_cliente-key  = ls_cliente-bukrs.
  ls_listbox_cliente-text = ls_cliente-butxt.
  APPEND ls_listbox_cliente TO it_listbox_clientes.
  CLEAR: ls_listbox_cliente.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_BUKRS2'
      values = it_listbox_clientes.

  READ TABLE it_clientes INTO ls_cliente INDEX 1.
  p_bukrs2 = ls_cliente-bukrs.

ENDFORM.

FORM fill_listbox_faturas.

  CLEAR it_listbox_faturas.

  LOOP AT it_faturas INTO ls_fatura.
    ls_listbox_fatura-key = ls_fatura-belnr.
    ls_listbox_fatura-text = ls_fatura-belnr.
    APPEND ls_listbox_fatura TO it_listbox_faturas.
    CLEAR: ls_fatura, ls_listbox_fatura.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_FATURA'
      values = it_listbox_faturas.

  SORT it_faturas BY belnr ASCENDING.
  READ TABLE it_faturas INTO ls_fatura INDEX 1.
  p_fatura = ls_fatura-belnr.

ENDFORM.
