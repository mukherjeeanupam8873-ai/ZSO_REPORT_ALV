*&--------------------------------------------------------------------*
*& Program     : ZSO_REPORT_ALV
*& Title       : Sales Order ALV Dashboard
*& Description : Interactive ALV Grid displaying Sales Orders with
*&               item-level detail, customer information, row-level
*&               status colouring, hotspot drill-down to VA03, and
*&               user-defined layout variant management.
*& Author      : Anupam Mukherjee
*& Roll No     : 2305197
*& Batch       : SAP ABAP Developer
*& Institute   : KIIT University
*& Created     : 2025
*& Tables      : VBAK, VBAP, KNA1
*&--------------------------------------------------------------------*
*& REVISION HISTORY
*&--------------------------------------------------------------------*
*& Version | Date       | Change Description
*& --------|------------|-------------------------------------------
*& 1.0     | 01.03.2025 | Initial build - data fetch + basic ALV
*& 1.1     | 10.03.2025 | Added status colour coding and hotspot
*& 1.2     | 20.03.2025 | Added variant save and selection screen
*&--------------------------------------------------------------------*

REPORT zso_report_alv
  LINE-SIZE 250.

*&--------------------------------------------------------------------*
*& TYPE DEFINITIONS
*&--------------------------------------------------------------------*
TYPES:
  " Main output row type combining all three tables
  BEGIN OF ty_order_row,

    " ── From VBAK (Sales Document Header) ──────────────────────────
    order_no   TYPE vbak-vbeln,       " Sales document number
    order_date TYPE vbak-audat,       " Date order was created
    sales_org  TYPE vbak-vkorg,       " Sales organisation key
    distr_ch   TYPE vbak-vtweg,       " Distribution channel
    division   TYPE vbak-spart,       " Division
    proc_stat  TYPE vbak-gbstk,       " Overall processing status
    hdr_value  TYPE vbak-netwr,       " Total net order value
    currency   TYPE vbak-waerk,       " Document currency key
    cust_no    TYPE vbak-kunnr,       " Sold-to customer number

    " ── From VBAP (Sales Document Item) ────────────────────────────
    item_no    TYPE vbap-posnr,       " Line item number
    material   TYPE vbap-matnr,       " Material number
    item_desc  TYPE vbap-arktx,       " Short text / description
    qty        TYPE vbap-kwmeng,      " Confirmed order quantity
    uom        TYPE vbap-vrkme,       " Unit of measure
    unit_price TYPE vbap-netpr,       " Net price per unit
    tax_amt    TYPE vbap-mwsbp,       " Tax amount on item

    " ── From KNA1 (Customer Master General) ────────────────────────
    cust_name  TYPE kna1-name1,       " Customer full name
    cust_city  TYPE kna1-ort01,       " Customer city
    cust_ctry  TYPE kna1-land1,       " Customer country key

    " ── Computed Display Fields (not stored in DB) ─────────────────
    row_clr    TYPE c LENGTH 4,       " ALV row colour control field
    stat_lbl   TYPE c LENGTH 20,      " Readable status label

  END OF ty_order_row,

  " Table type for the above
  tt_order_rows TYPE STANDARD TABLE OF ty_order_row WITH DEFAULT KEY.

*&--------------------------------------------------------------------*
*& CONSTANTS
*&--------------------------------------------------------------------*
CONSTANTS:
  " Program identifier (used for layout variant)
  gc_progname  TYPE sy-repid    VALUE 'ZSO_REPORT_ALV',

  " Default layout variant name
  gc_dflt_var  TYPE disvariant-variant VALUE '/STANDARD',

  " ALV Colour Codes — format: C[colour 1-9][intensity 1-2][0]
  "   Intensity 1 = normal, 2 = intensified (bold background)
  gc_clr_open  TYPE c LENGTH 4 VALUE 'C310',  " Green  — Open
  gc_clr_part  TYPE c LENGTH 4 VALUE 'C510',  " Yellow — Partial
  gc_clr_done  TYPE c LENGTH 4 VALUE 'C110',  " Blue   — Complete
  gc_clr_blck  TYPE c LENGTH 4 VALUE 'C610',  " Red    — Blocked
  gc_clr_dflt  TYPE c LENGTH 4 VALUE 'C010'.  " White  — Default/Unknown

*&--------------------------------------------------------------------*
*& SELECTION SCREEN
*&--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK sel_main WITH FRAME TITLE TEXT-s01.
  " TEXT-s01 = 'Order Selection Criteria'
  SELECT-OPTIONS:
    so_sorg  FOR vbak-vkorg,     " Filter: Sales Organisation
    so_cust  FOR vbak-kunnr,     " Filter: Customer Number
    so_mat   FOR vbap-matnr,     " Filter: Material Number
    so_stat  FOR vbak-gbstk,     " Filter: Processing Status
    so_date  FOR vbak-audat.     " Filter: Order Creation Date
SELECTION-SCREEN END OF BLOCK sel_main.

SELECTION-SCREEN BEGIN OF BLOCK sel_opts WITH FRAME TITLE TEXT-s02.
  " TEXT-s02 = 'Display Options'
  PARAMETERS:
    pa_limit TYPE i          DEFAULT 5000,     " Row fetch limit
    pa_grid  TYPE c          AS CHECKBOX DEFAULT 'X', " X=ALV Grid
    pa_vari  TYPE disvariant-variant DEFAULT '/STANDARD'. " Layout variant
SELECTION-SCREEN END OF BLOCK sel_opts.

*&--------------------------------------------------------------------*
*& LOCAL CLASS: EVENT HANDLER
*& Handles ALV grid events using the OO pattern
*&--------------------------------------------------------------------*
CLASS lcl_alv_handler DEFINITION.
  PUBLIC SECTION.

    " Handles custom function codes from the ALV toolbar
    CLASS-METHODS handle_toolbar_cmd
      FOR EVENT added_function OF cl_gui_alv_grid
      IMPORTING e_ucomm.

    " Handles double-click / hotspot click on cells
    CLASS-METHODS handle_cell_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id es_row_no.

ENDCLASS.

CLASS lcl_alv_handler IMPLEMENTATION.

  METHOD handle_toolbar_cmd.
    CASE e_ucomm.

      WHEN 'ZAM_REFRESH'.
        " Re-fetch data and refresh the grid display
        PERFORM fetch_orders.
        PERFORM apply_row_colours.
        MESSAGE 'Data refreshed successfully.' TYPE 'S'.

      WHEN 'ZAM_HELP'.
        " Show a brief usage help popup
        MESSAGE 'Select rows and use toolbar options. Click Order No. to open VA03.' TYPE 'I'.

      WHEN OTHERS.
        " All other commands (sort, filter, etc.) handled by ALV internally

    ENDCASE.
  ENDMETHOD.

  METHOD handle_cell_click.
    " Navigate to VA03 when user clicks on an Order Number cell
    DATA: lv_docno TYPE vbeln_va.
    FIELD-SYMBOLS: <lfs_row> TYPE ty_order_row.

    READ TABLE gt_orders ASSIGNING <lfs_row> INDEX e_row_id-index.
    IF sy-subrc = 0.
      lv_docno = <lfs_row>-order_no.
      SET PARAMETER ID 'AUN' FIELD lv_docno.
      CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*&--------------------------------------------------------------------*
*& GLOBAL DATA
*&--------------------------------------------------------------------*
DATA:
  gt_orders    TYPE tt_order_rows,           " Main data table
  go_dock      TYPE REF TO cl_gui_docking_container, " Docking container
  go_grid      TYPE REF TO cl_gui_alv_grid,  " ALV grid instance
  go_handler   TYPE REF TO lcl_alv_handler,  " Event handler instance
  gst_layout   TYPE lvc_s_layo,              " ALV layout settings
  gst_variant  TYPE disvariant,              " Layout variant settings
  gt_fcat      TYPE lvc_t_fcat,              " Field catalogue table
  gv_rowcount  TYPE i.                       " Total rows fetched

*&--------------------------------------------------------------------*
*& INITIALIZATION — Runs before selection screen is shown
*&--------------------------------------------------------------------*
INITIALIZATION.
  " Pre-fill date range with current calendar year
  DATA: lv_year_start TYPE sy-datum.
  lv_year_start = sy-datum.
  lv_year_start+4(4) = '0101'.

  so_date-sign   = 'I'.
  so_date-option = 'BT'.
  so_date-low    = lv_year_start.
  so_date-high   = sy-datum.
  APPEND so_date.

*&--------------------------------------------------------------------*
*& AT SELECTION SCREEN — Input validation before execution
*&--------------------------------------------------------------------*
AT SELECTION-SCREEN.

  " Enforce a non-empty date range
  IF so_date[] IS INITIAL.
    MESSAGE 'Please specify an order date range before running the report.' TYPE 'E'.
  ENDIF.

  " Clamp the row limit to a sensible range
  IF pa_limit <= 0.
    pa_limit = 1000.
  ELSEIF pa_limit > 50000.
    pa_limit = 50000.
    MESSAGE 'Row limit capped at 50,000 for system performance.' TYPE 'W'.
  ENDIF.

*&--------------------------------------------------------------------*
*& START-OF-SELECTION — Entry point after selection screen
*&--------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_orders.

  IF gt_orders IS INITIAL.
    MESSAGE 'No Sales Orders matched your selection. Please adjust filters.' TYPE 'I'.
    RETURN.
  ENDIF.

  PERFORM apply_row_colours.

*&--------------------------------------------------------------------*
*& END-OF-SELECTION — Trigger display after data is ready
*&--------------------------------------------------------------------*
END-OF-SELECTION.
  IF pa_grid = abap_true.
    CALL SCREEN 100.
  ELSE.
    PERFORM show_list_alv.
  ENDIF.

*&--------------------------------------------------------------------*
*& FORM: FETCH_ORDERS
*& Retrieves all required data in a single three-table JOIN.
*& Joins VBAK (header) → VBAP (items) → KNA1 (customer master).
*&--------------------------------------------------------------------*
FORM fetch_orders.

  " Check user has display authorisation for the given Sales Org
  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
    ID 'VKORG' FIELD so_sorg-low
    ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    MESSAGE 'Authorisation missing for selected Sales Organisation.' TYPE 'E'.
    RETURN.
  ENDIF.

  " Wipe any previously fetched data before re-selecting
  CLEAR: gt_orders, gv_rowcount.

  SELECT
      vbak~vbeln  AS order_no,
      vbak~audat  AS order_date,
      vbak~vkorg  AS sales_org,
      vbak~vtweg  AS distr_ch,
      vbak~spart  AS division,
      vbak~gbstk  AS proc_stat,
      vbak~netwr  AS hdr_value,
      vbak~waerk  AS currency,
      vbak~kunnr  AS cust_no,
      vbap~posnr  AS item_no,
      vbap~matnr  AS material,
      vbap~arktx  AS item_desc,
      vbap~kwmeng AS qty,
      vbap~vrkme  AS uom,
      vbap~netpr  AS unit_price,
      vbap~mwsbp  AS tax_amt,
      kna1~name1  AS cust_name,
      kna1~ort01  AS cust_city,
      kna1~land1  AS cust_ctry
    INTO CORRESPONDING FIELDS OF TABLE @gt_orders
    UP TO @pa_limit ROWS
    FROM vbak
      INNER JOIN vbap ON vbap~vbeln = vbak~vbeln
      INNER JOIN kna1 ON kna1~kunnr = vbak~kunnr
    WHERE vbak~vkorg IN @so_sorg
      AND vbak~kunnr IN @so_cust
      AND vbak~audat IN @so_date
      AND vbak~gbstk IN @so_stat
      AND vbap~matnr IN @so_mat
    ORDER BY vbak~vbeln, vbap~posnr.

  gv_rowcount = lines( gt_orders ).
  MESSAGE |{ gv_rowcount } order line(s) loaded.| TYPE 'S'.

ENDFORM.

*&--------------------------------------------------------------------*
*& FORM: APPLY_ROW_COLOURS
*& Sets ROW_CLR and STAT_LBL fields based on PROC_STAT (GBSTK).
*& GBSTK values:
*&   ' ' or 'A' = Open (not yet started)
*&   'B'        = Partially processed (e.g. partial delivery)
*&   'C'        = Fully processed / completed
*&   'D'        = Blocked for further processing
*&--------------------------------------------------------------------*
FORM apply_row_colours.
  FIELD-SYMBOLS: <lfs> TYPE ty_order_row.

  LOOP AT gt_orders ASSIGNING <lfs>.
    CASE <lfs>-proc_stat.
      WHEN space OR 'A'.
        <lfs>-row_clr  = gc_clr_open.
        <lfs>-stat_lbl = 'Open'.
      WHEN 'B'.
        <lfs>-row_clr  = gc_clr_part.
        <lfs>-stat_lbl = 'In Progress'.
      WHEN 'C'.
        <lfs>-row_clr  = gc_clr_done.
        <lfs>-stat_lbl = 'Completed'.
      WHEN 'D'.
        <lfs>-row_clr  = gc_clr_blck.
        <lfs>-stat_lbl = 'Blocked'.
      WHEN OTHERS.
        <lfs>-row_clr  = gc_clr_dflt.
        <lfs>-stat_lbl = 'Unknown'.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*&--------------------------------------------------------------------*
*& FORM: BUILD_FIELD_CATALOGUE
*& Manually defines each ALV column using a helper macro.
*& This gives full control over headers, width, hotspot, and alignment.
*&--------------------------------------------------------------------*
FORM build_field_catalogue.
  DATA: lwa_fc TYPE lvc_s_fcat.

  " Macro: populate one field catalogue entry and append it
  "        Args: fieldname, header text, output length,
  "              ref table, ref field, hotspot (X or ''), justify
  DEFINE build_col.
    CLEAR lwa_fc.
    lwa_fc-fieldname = &1.
    lwa_fc-coltext   = &2.
    lwa_fc-outputlen = &3.
    lwa_fc-ref_table = &4.
    lwa_fc-ref_field = &5.
    lwa_fc-hotspot   = &6.
    lwa_fc-just      = &7.
    APPEND lwa_fc TO gt_fcat.
  END-OF-DEFINITION.

  "          Fieldname    Header              Len  RefTab  RefFld   Hot  Just
  build_col 'ORDER_NO'  'Order No.'          10  'VBAK'  'VBELN'  'X'  'L'.
  build_col 'ORDER_DATE' 'Order Date'        10  'VBAK'  'AUDAT'  ''   'C'.
  build_col 'SALES_ORG' 'Sales Org'           4  'VBAK'  'VKORG'  ''   'C'.
  build_col 'CUST_NO'   'Customer'           10  'VBAK'  'KUNNR'  ''   'L'.
  build_col 'CUST_NAME' 'Customer Name'      30  'KNA1'  'NAME1'  ''   'L'.
  build_col 'CUST_CITY' 'City'               15  'KNA1'  'ORT01'  ''   'L'.
  build_col 'CUST_CTRY' 'Country'             3  'KNA1'  'LAND1'  ''   'C'.
  build_col 'ITEM_NO'   'Item'                6  'VBAP'  'POSNR'  ''   'R'.
  build_col 'MATERIAL'  'Material'           18  'VBAP'  'MATNR'  ''   'L'.
  build_col 'ITEM_DESC' 'Description'        30  'VBAP'  'ARKTX'  ''   'L'.
  build_col 'QTY'       'Quantity'           13  'VBAP'  'KWMENG' ''   'R'.
  build_col 'UOM'       'UoM'                 3  'VBAP'  'VRKME'  ''   'C'.
  build_col 'UNIT_PRICE' 'Unit Price'        13  'VBAP'  'NETPR'  ''   'R'.
  build_col 'HDR_VALUE' 'Order Value'        15  'VBAK'  'NETWR'  ''   'R'.
  build_col 'CURRENCY'  'Currency'            5  'VBAK'  'WAERK'  ''   'C'.
  build_col 'STAT_LBL'  'Status'             15  ''      ''       ''   'C'.

  " Hide technical fields that drive display logic but should not appear
  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<lfc>).
    IF <lfc>-fieldname = 'ROW_CLR'
    OR <lfc>-fieldname = 'PROC_STAT'
    OR <lfc>-fieldname = 'DISTR_CH'
    OR <lfc>-fieldname = 'DIVISION'.
      <lfc>-no_out = abap_true.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&--------------------------------------------------------------------*
*& FORM: BUILD_LAYOUT_SETTINGS
*& Populates gst_layout (LVC_S_LAYO) and gst_variant (DISVARIANT).
*&--------------------------------------------------------------------*
FORM build_layout_settings.
  CLEAR gst_layout.

  gst_layout-zebra       = abap_true.   " Alternating row shading
  gst_layout-cwidth_opt  = abap_true.   " Auto-fit column widths
  gst_layout-info_fname  = 'ROW_CLR'.  " Field controlling row colour
  gst_layout-sel_mode    = 'D'.         " Multi-row selection
  gst_layout-no_merging  = abap_true.   " Prevent cell merging
  gst_layout-grid_title  =
    |Sales Order Dashboard  |  { gv_rowcount } rows  |  { sy-datum }|.

  " Layout variant configuration
  gst_variant-report  = gc_progname.
  gst_variant-variant = pa_vari.
ENDFORM.

*&--------------------------------------------------------------------*
*& FORM: SHOW_LIST_ALV
*& Fallback display mode using the classic function module ALV.
*& Useful for print-friendly / batch output.
*&--------------------------------------------------------------------*
FORM show_list_alv.
  DATA: lt_sort  TYPE lvc_t_sort,
        lwa_sort TYPE lvc_s_sort.

  " Default sort: Order number ascending, then item number ascending
  lwa_sort-fieldname = 'ORDER_NO'.  lwa_sort-up = abap_true.
  APPEND lwa_sort TO lt_sort.       CLEAR lwa_sort.
  lwa_sort-fieldname = 'ITEM_NO'.   lwa_sort-up = abap_true.
  APPEND lwa_sort TO lt_sort.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = gc_progname
      i_callback_pf_status_set = 'SET_SCREEN_STATUS'
      i_callback_user_command  = 'HANDLE_USER_CMD'
      is_layout_lvc            = gst_layout
      it_fieldcat_lvc          = gt_fcat
      it_sort_lvc              = lt_sort
      is_variant               = gst_variant
      i_save                   = 'A'
    TABLES
      t_outtab                 = gt_orders
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE 'ALV list display encountered an error.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&--------------------------------------------------------------------*
*& FORM: SET_SCREEN_STATUS  (callback for REUSE_ALV list mode)
*&--------------------------------------------------------------------*
FORM set_screen_status USING rt_excl TYPE slis_t_extab.
  SET PF-STATUS 'ZAM_STATUS' EXCLUDING rt_excl.
ENDFORM.

*&--------------------------------------------------------------------*
*& FORM: HANDLE_USER_CMD  (callback for REUSE_ALV list mode)
*&--------------------------------------------------------------------*
FORM handle_user_cmd USING pv_cmd      TYPE sy-ucomm
                           pst_sel     TYPE slis_selfield.
  CASE pv_cmd.

    WHEN 'ZAM_REFRESH'.
      PERFORM fetch_orders.
      PERFORM apply_row_colours.
      pst_sel-refresh = abap_true.

    WHEN '&IC1'.
      " Hotspot click in list mode — navigate to VA03
      IF pst_sel-fieldname = 'ORDER_NO'.
        SET PARAMETER ID 'AUN' FIELD pst_sel-value.
        CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
      ENDIF.

  ENDCASE.
ENDFORM.

*&--------------------------------------------------------------------*
*& DYNPRO SCREEN 100 — MODULE POOL
*& Screen 100 must be created in SE51 for program ZSO_REPORT_ALV.
*& Add a Docking Container or Custom Control named 'ZAM_MAIN'.
*&--------------------------------------------------------------------*

MODULE init_screen_100 OUTPUT.
  " Set GUI Status and title bar
  SET PF-STATUS 'ZAM_STATUS'.
  SET TITLEBAR 'ZAM_TITLE'.

  " Only create container and grid on first entry
  IF go_grid IS INITIAL.

    " Build field catalogue and layout before creating grid
    PERFORM build_field_catalogue.
    PERFORM build_layout_settings.

    " Instantiate the docking container (alternative to custom container)
    " Docking containers do not require a Custom Control in SE51 —
    " they dock to a screen edge and resize automatically.
    CREATE OBJECT go_dock
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_left
        extension = 5000
      EXCEPTIONS
        OTHERS    = 1.

    IF sy-subrc <> 0.
      MESSAGE 'Docking container initialisation failed.' TYPE 'A'.
    ENDIF.

    " Create the ALV grid as a child of the docking container
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_dock
      EXCEPTIONS
        OTHERS   = 1.

    IF sy-subrc <> 0.
      MESSAGE 'ALV Grid initialisation failed.' TYPE 'A'.
    ENDIF.

    " Register the event handler for toolbar commands and hotspot clicks
    CREATE OBJECT go_handler.
    SET HANDLER lcl_alv_handler=>handle_toolbar_cmd FOR go_grid.
    SET HANDLER lcl_alv_handler=>handle_cell_click  FOR go_grid.

    " Bind data and field catalogue to the grid for first-time display
    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gst_layout
        is_variant      = gst_variant
        i_save          = 'A'
        i_default       = 'X'
      CHANGING
        it_outtab       = gt_orders
        it_fieldcatalog = gt_fcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.

    IF sy-subrc <> 0.
      MESSAGE 'ALV Grid could not display data.' TYPE 'A'.
    ENDIF.

  ELSE.
    " Grid already exists — just refresh the visible rows
    CALL METHOD go_grid->refresh_table_display
      EXPORTING
        is_stable = VALUE #( row = abap_true col = abap_true )
      EXCEPTIONS
        finished  = 1
        OTHERS    = 2.
  ENDIF.

ENDMODULE.

MODULE process_user_cmd INPUT.
  DATA: lv_cmd TYPE sy-ucomm.
  lv_cmd   = sy-ucomm.
  CLEAR sy-ucomm.

  CASE lv_cmd.

    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      " Clean up objects before leaving screen
      IF go_grid IS BOUND.
        go_grid->free( ).
      ENDIF.
      IF go_dock IS BOUND.
        go_dock->free( ).
      ENDIF.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'ZAM_REFRESH'.
      PERFORM fetch_orders.
      PERFORM apply_row_colours.

    WHEN OTHERS.
      " All other commands are processed by the ALV grid internally

  ENDCASE.
ENDMODULE.
