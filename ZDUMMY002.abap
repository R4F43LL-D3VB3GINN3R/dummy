  METHOD zif_tbfiles~get_cost_centers.

    "----------------------------------
    "Created by: RLA@SBX
    "Date: 04.04.2025
    "Updates: Company Table (bukrs-butxt)
    "Updates Dates: 08.04.2025
    "----------------------------------

    CLEAR me->gt_cost_centers.
    CLEAR me->gs_result.

    "get company code and language
    zif_tbfiles~get_company(
      EXPORTING
        i_bukrs   = i_company
      IMPORTING
        e_company = DATA(ls_company)
    ).

    "company verification
    IF ls_company IS INITIAL.
      gs_result-rc      = 1.
      gs_result-message = | Company Code { i_company } not found |.
      e_result          = me->gs_result.
      RETURN.
    ENDIF.

    "validate optional dates to query
    DATA: datein TYPE datbi.
    DATA: dateout TYPE datbi.
    datein  = i_datab.
    dateout = i_datbi.

    "set default values to dates
    IF datein = '00000000'.
      datein = '19000101'.
    ENDIF.
    IF dateout = '00000000'.
      dateout = '99991231'.
    ENDIF.

    "get cost centers
    SELECT csks~kostl,                                         "Cost Center
           cskt~ktext,                                         "Description
           csks~prctr,                                         "Profit Center
           csks~datab,                                         "Date Begin validation
           csks~datbi,                                         "Date End validation
           csks~verak_user                                     "Manager
      FROM csks                                                "Master Data Cost Center
      INNER JOIN cskt                                          "Cost Center Texts
      ON csks~kostl EQ cskt~kostl                              "Cost Center = Cost Center
      INTO CORRESPONDING FIELDS OF TABLE @me->gt_cost_centers  "Table to Cost Center
      WHERE csks~bukrs EQ @ls_company-bukrs                    "Where Company Code eq XXXX
      AND   cskt~spras EQ @ls_company-spras                    "And Language is eq Company Language
      AND csks~datab GE @datein                                "And initial date ge datab
      AND csks~datbi LE @dateout                               "And end date le datbi
      GROUP BY csks~kostl,
               csks~datab,
               csks~datbi,
               csks~bukrs,
               cskt~ktext,
               csks~prctr,
               csks~verak_user.

    "loop for all cost centers
    LOOP AT me->gt_cost_centers INTO me->gs_cost_center.

      "get companies from all cost centers
      SELECT bukrs
        FROM csks
        INTO CORRESPONDING FIELDS OF TABLE me->gs_cost_center-company
        WHERE csks~kostl EQ me->gs_cost_center-kostl.

      "loop for all companies
      LOOP AT me->gs_cost_center-company ASSIGNING FIELD-SYMBOL(<ls_company>).

        "get_texts from companies
        SELECT SINGLE butxt
          INTO @<ls_company>-butxt
          FROM t001
          WHERE bukrs = @<ls_company>-bukrs.

      ENDLOOP.

      "update internal table
      MODIFY me->gt_cost_centers FROM me->gs_cost_center.

    ENDLOOP.

    "cost center verification
    IF me->gt_cost_centers IS INITIAL.
      gs_result-rc      = 1.
      gs_result-message = | Cost Centers to Company Code { i_company } not found |.
      e_result = me->gs_result.
      RETURN.
    ENDIF.

    "---------------------------------------------------------
    "                     MARINHEIRO
    "---------------------------------------------------------
    "---------------------------------------------------------

    DATA:
      lt_page  TYPE ztt_03_cost_cent, "página
      lv_start TYPE i,                "index inicial
      lv_end   TYPE i,                "index final
      lv_index TYPE i VALUE 1.        "index atual

    DATA: pagenumber TYPE i VALUE 1. "numero da pagina

    DATA: rows TYPE i.                   "quantidade de linhas totais
    rows = lines( me->gt_cost_centers ). "total de linhas para output

    DATA(lv_pagesize) = ceil( rows / i_pages ).    "quantidade de linhas por pagina
    DATA(lv_total) = lines( me->gt_cost_centers ). "total de linhas que pode receber update

    "enquanto o total de paginas nao terminar
    WHILE lv_index <= lv_total.

      CLEAR lt_page.

      lv_start = lv_index.
      lv_end   = lv_index + lv_pagesize - 1.

      "ajuste para a ultima linha
      IF lv_end > lv_total.
        lv_end = lv_total.
      ENDIF.

      LOOP AT me->gt_cost_centers INTO DATA(ls_centers) FROM lv_start TO lv_end.
        APPEND ls_centers TO lt_page.
      ENDLOOP.

      me->gs_page_cost_center-page = |Page | && pagenumber.
      ADD 1 TO pagenumber.
      me->gs_page_cost_center-content = lt_page.
      APPEND me->gs_page_cost_center TO me->gt_pages_cost_centers.

      ADD lv_pagesize TO lv_index.

    ENDWHILE.

    e_cost_centers = me->gt_pages_cost_centers.

    "succesfull verification
    gs_result-rc      = 0.
    gs_result-message = | Ok |.

    "output
    e_rows         = rows.
    e_cost_centers = me->gt_pages_cost_centers.
    e_result       = me->gs_result.

  ENDMETHOD.
