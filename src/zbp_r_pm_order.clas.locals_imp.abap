CLASS lhc_ZR_PM_ORDER DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_mail,
             uname         TYPE uname,
             subject       TYPE string,
             body          TYPE string,
             docType(1),
             docNumber(15),
           END OF tY_MAIL.

    TYPES: BEGIN OF ty_order_update,
             maintenanceorder         TYPE aufnr,
             maintordbasicstartdate   TYPE pm_ordgstrp,
             maintordbasicstarttime   TYPE co_gsuzp,
             maintordbasicenddate     TYPE co_gltrp,
             maintordbasicendtime     TYPE co_gluzp,
             maintordbasicstartdate_x TYPE abap_bool,
             maintordbasicstarttime_x TYPE abap_bool,
             maintordbasicenddate_x   TYPE abap_bool,
             maintordbasicendtime_x   TYPE abap_bool,
           END OF ty_order_update.

    TYPES: BEGIN OF ty_order_start,
             maintenanceorder        TYPE aufnr,
             NotificationCreatedUser TYPE uname,
             notificationnumber      TYPE qmnum,
             maintordbasicstartdate  TYPE pm_ordgstrp,
             maintordbasicstarttime  TYPE co_gsuzp,
           END OF ty_order_start.

    TYPES: BEGIN OF ty_order_confirm,
             maintenanceorder        TYPE aufnr,
             NotificationCreatedUser TYPE uname,
             notificationnumber      TYPE qmnum,
             confirmnote             tYPE string,
             conf_start_date         TYPE sy-datum,
             conf_start_time         TYPE sy-uzeit,
             conf_end_date           TYPE sy-datum,
             conf_end_time           TYPE sy-uzeit,
           END OF ty_order_confirm.


    TYPES: BEGIN OF ty_order_approve,
             _ar                TYPE char1,
             maintenanceorder   TYPE aufnr,
             notificationnumber TYPE qmnum,
             approvenote        tYPE string,
             actual_start_date  TYPE sy-datum,
             actual_start_time  TYPE sy-uzeit,
             actual_end_date    TYPE sy-datum,
             actual_end_time    TYPE sy-uzeit,
           END OF ty_order_approve.
    TYPES:BEGIN OF ty_order_comp.
            INCLUDE TYPE zr_pm_order_comp.
    TYPES: updkz(1),
          END OF  ty_order_comp.
    TYPES:BEGIN OF ty_order_op.
            INCLUDE TYPE zr_pm_order_operation.
    TYPES: updkz(1),
          END OF  ty_order_op.

    TYPES:BEGIN OF ty_order_partner.
            INCLUDE TYPE zr_pm_order_partner.
    TYPES: updkz(1),
          END OF  ty_order_partner.

    CLASS-DATA gt_order_update_buffer  TYPE TABLE OF ty_order_update.
    CLASS-DATA gt_order_start_buffer   TYPE TABLE OF ty_order_start.
    CLASS-DATA gt_order_confirm_buffer TYPE TABLE OF ty_order_confirm.
    CLASS-DATA gt_order_approve_buffer TYPE TABLE OF ty_order_approve.
    CLASS-DATA gt_order_component_buffer TYPE TABLE OF ty_order_comp.
    CLASS-DATA gt_order_operation_buffer TYPE TABLE OF ty_order_op.
    CLASS-DATA gt_order_partner_buffer   TYPE TABLE OF ty_order_partner.
    " Tracks highest assigned op number per order within the current LUW
    TYPES: BEGIN OF ty_op_counter,
             maintenanceorder TYPE aufnr,
             max_op_n         TYPE int4,
           END OF ty_op_counter.
    CLASS-DATA gt_op_counters TYPE TABLE OF ty_op_counter WITH KEY maintenanceorder.
    " Tracks highest assigned partner counter per order within the current LUW
    TYPES: BEGIN OF ty_part_counter,
             maintenanceorder TYPE aufnr,
             max_part_n       TYPE i,
           END OF ty_part_counter.
    CLASS-DATA gt_part_counters TYPE TABLE OF ty_part_counter WITH KEY maintenanceorder.
    CLASS-DATA gs_mail_Daata TYPE ty_mail.

    CLASS-METHODS sending_email
      IMPORTING is_mail          TYPE ty_mail
      RETURNING VALUE(rv_result) TYPE abap_bool.

  PRIVATE SECTION.

    " Action metodları — RESULT parametresi var
    METHODS start_order FOR MODIFY
      IMPORTING keys FOR ACTION zr_pm_order~start_order RESULT result.

    METHODS confirm_order FOR MODIFY
      IMPORTING keys FOR ACTION zr_pm_order~confirm_order RESULT result.

    METHODS approve_order FOR MODIFY
      IMPORTING keys FOR ACTION zr_pm_order~approve_order RESULT result.

    METHODS reject_order FOR MODIFY
      IMPORTING keys FOR ACTION zr_pm_order~reject_order RESULT result.

    "METHODS release_order FOR MODIFY
    "  IMPORTING keys FOR ACTION zr_pm_order~release_order RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zr_pm_order RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zr_pm_order RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_pm_order.


    METHODS read FOR READ
      IMPORTING keys FOR READ zr_pm_order RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zr_pm_order.

    METHODS rba_Component FOR READ
      IMPORTING keys_rba FOR READ zr_pm_order\_Component FULL result_requested RESULT result LINK association_links.

    METHODS rba_Operation FOR READ
      IMPORTING keys_rba FOR READ zr_pm_order\_Operation FULL result_requested RESULT result LINK association_links.
    METHODS rba_Partner FOR READ
      IMPORTING keys_rba FOR READ zr_pm_order\_Partner FULL result_requested RESULT result LINK association_links.

    METHODS earlynumbering_cba_Component FOR NUMBERING
      IMPORTING entities FOR CREATE zr_pm_order\_Component.

    METHODS earlynumbering_cba_Operation FOR NUMBERING
      IMPORTING entities FOR CREATE zr_pm_order\_Operation.

    METHODS earlynumbering_cba_Partner FOR NUMBERING
      IMPORTING entities FOR CREATE zr_pm_order\_Partner.

    METHODS cba_Component FOR MODIFY
      IMPORTING entities_cba FOR CREATE zr_pm_order\_Component.
    METHODS cba_Operation FOR MODIFY
      IMPORTING entities_cba FOR CREATE zr_pm_order\_Operation.

    METHODS cba_Partner FOR MODIFY
      IMPORTING entities_cba FOR CREATE zr_pm_order\_Partner.

    METHODS is_notifier
      IMPORTING iv_aufnr         TYPE aufnr
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS is_supervisor
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS is_technician
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS get_user_status
      IMPORTING iv_aufnr         TYPE aufnr
      RETURNING VALUE(rv_status) TYPE char20.

ENDCLASS.


CLASS lhc_ZR_PM_ORDER IMPLEMENTATION.
  METHOD earlynumbering_cba_Component.
    LOOP AT entities INTO DATA(ls_parent).

      SELECT SINGLE MAX( reservationitem )
        FROM zr_pm_order_comp
        WHERE maintenanceorder = @ls_parent-%key-maintenanceorder
        INTO @DATA(lv_max_db).

      SELECT SINGLE MAX( reservationitem )
        FROM zpm_orderc_d
        WHERE maintenanceorder = @ls_parent-%key-maintenanceorder
        INTO @DATA(lv_max_draft).

      DATA(lv_base) = COND zr_pm_order_comp-reservationitem(
        WHEN lv_max_db > lv_max_draft
        THEN lv_max_db
        ELSE lv_max_draft ).

      LOOP AT ls_parent-%target INTO DATA(ls_new_comp).
        lv_base += 1.
        INSERT VALUE #( %cid                          = ls_new_comp-%cid
                        %is_draft                     = ls_new_comp-%is_draft
                        MaintenanceOrder              = ls_parent-%key-MaintenanceOrder
                        MaintOrderComponentInternalID = lv_base
                        ReservationItem               = lv_base )
               INTO TABLE mapped-component.
      ENDLOOP.

      CLEAR: lv_max_db, lv_max_draft, lv_base.

    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Operation.
    LOOP AT entities INTO DATA(ls_parent).
      DATA(lv_order) = ls_parent-%key-maintenanceorder.

      " DB: max operation number ever used on this order — all AFVC rows regardless of PHFLG.
      " Using the view (zr_pm_order_operation) would miss soft-deleted rows and cause reuse collisions.
      DATA lv_max_db TYPE zr_pm_order_operation-maintenanceorderoperation.
      SELECT SINGLE aufpl FROM caufv WHERE aufnr = @lv_order INTO @DATA(lv_aufpl_en).
      IF sy-subrc = 0.
        DATA lv_max_afvc TYPE vornr.
        SELECT SINGLE MAX( vornr ) FROM afvc
          WHERE aufpl = @lv_aufpl_en
          INTO @lv_max_afvc.
        lv_max_db = lv_max_afvc.
      ENDIF.

      " Draft: max from newly created rows only (draftentityoperationcode='C')
      " These are draft rows not yet committed to DB
      DATA lv_max_draft TYPE zpm_ordero_d-maintenanceorderoperation.
      SELECT SINGLE MAX( maintenanceorderoperation )
        FROM zpm_ordero_d
        WHERE maintenanceorder         = @lv_order
          AND draftentityoperationcode = 'C'
        INTO @lv_max_draft.

      " LUW counter: numbers assigned in this transaction (not yet written to draft)
      DATA(lv_max_luw_n) = 0.
      DATA(lv_cnt_exists) = abap_false.
      READ TABLE gt_op_counters ASSIGNING FIELD-SYMBOL(<cnt>)
        WITH KEY maintenanceorder = lv_order.
      IF sy-subrc = 0.
        lv_max_luw_n  = <cnt>-max_op_n.
        lv_cnt_exists = abap_true.
      ENDIF.

      " Numeric max across all three sources (all DB, draft, LUW)
      DATA(lv_max_db_n)    = CONV int4( lv_max_db ).
      DATA(lv_max_draft_n) = CONV int4( lv_max_draft ).
      DATA(lv_base_n)      = COND int4(
        WHEN lv_max_db_n >= lv_max_draft_n AND lv_max_db_n >= lv_max_luw_n THEN lv_max_db_n
        WHEN lv_max_draft_n >= lv_max_luw_n                                 THEN lv_max_draft_n
        ELSE lv_max_luw_n ).

      SELECT SINGLE aufpl
        FROM caufv
        WHERE aufnr = @lv_order
        INTO @DATA(lv_aufpl).

      LOOP AT ls_parent-%target INTO DATA(ls_new_op).
        lv_base_n = lv_base_n + 10.
        DATA(lv_op_padded) = CONV zr_pm_order_operation-maintenanceorderoperation(
                               |{ lv_base_n WIDTH = 4 ALIGN = RIGHT PAD = '0' }| ).
        INSERT VALUE #( %cid                      = ls_new_op-%cid
                        %is_draft                 = ls_new_op-%is_draft
                        MaintenanceOrder          = lv_order
                        MaintOrderRoutingNumber   = lv_aufpl
                        MaintenanceOrderOperation = lv_op_padded )
               INTO TABLE mapped-zr_pm_order_operation.
      ENDLOOP.

      IF lv_cnt_exists = abap_true.
        <cnt>-max_op_n = lv_base_n.
      ELSE.
        INSERT VALUE #( maintenanceorder = lv_order
                        max_op_n        = lv_base_n )
               INTO TABLE gt_op_counters.
      ENDIF.

      CLEAR: lv_max_db, lv_max_afvc, lv_max_draft, lv_max_db_n, lv_max_draft_n,
             lv_max_luw_n, lv_cnt_exists, lv_base_n, lv_aufpl, lv_aufpl_en, lv_op_padded.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Partner.
    LOOP AT entities INTO DATA(ls_parent).
      DATA(lv_order_p) = ls_parent-%key-maintenanceorder.

      SELECT SINGLE MAX( partnercounter )
        FROM zv_pm_order_partner
        WHERE maintenanceorder = @lv_order_p
        INTO @DATA(lv_max_db_p).

      " Restrict to newly created draft rows (not yet in DB) — same pattern as operations
      SELECT SINGLE MAX( partnercounter )
        FROM zpm_orderp_d
        WHERE maintenanceorder         = @lv_order_p
          AND draftentityoperationcode = 'C'
        INTO @DATA(lv_max_draft_p).

      " LUW counter: highest counter assigned in this transaction (not yet in DB or draft)
      DATA lv_max_luw_p TYPE i.
      DATA lv_cnt_exists_p TYPE abap_bool.
      READ TABLE gt_part_counters ASSIGNING FIELD-SYMBOL(<pcnt>)
        WITH KEY maintenanceorder = lv_order_p.
      IF sy-subrc = 0.
        lv_max_luw_p    = <pcnt>-max_part_n.
        lv_cnt_exists_p = abap_true.
      ENDIF.

      DATA(lv_max_db_n_p)    = CONV i( lv_max_db_p ).
      DATA(lv_max_draft_n_p) = CONV i( lv_max_draft_p ).
      DATA(lv_base_p) = COND i(
        WHEN lv_max_db_n_p >= lv_max_draft_n_p AND lv_max_db_n_p >= lv_max_luw_p THEN lv_max_db_n_p
        WHEN lv_max_draft_n_p >= lv_max_luw_p                                     THEN lv_max_draft_n_p
        ELSE lv_max_luw_p ).

      DATA(lv_objnr_en) = CONV j_objnr( |OR{ lv_order_p ALPHA = IN }| ).

      LOOP AT ls_parent-%target INTO DATA(ls_new_part).
        " A row is existing only when its counter is non-initial AND already in IHPA
        DATA lv_ihpa_exists TYPE abap_bool.
        IF ls_new_part-PartnerCounter IS NOT INITIAL.
          SELECT SINGLE @abap_true FROM ihpa
            WHERE objnr   = @lv_objnr_en
              AND counter = @ls_new_part-PartnerCounter
            INTO @lv_ihpa_exists.
        ENDIF.

        IF lv_ihpa_exists = abap_true.
          " Existing committed partner — preserve its original counter
          INSERT VALUE #( %cid             = ls_new_part-%cid
                          %is_draft        = ls_new_part-%is_draft
                          MaintenanceOrder = lv_order_p
                          PartnerFunction  = 'VU'
                          PartnerCounter   = ls_new_part-PartnerCounter )
                 INTO TABLE mapped-zr_pm_order_partner.
        ELSE.
          " Truly new row — assign next counter
          lv_base_p += 1.
          INSERT VALUE #( %cid             = ls_new_part-%cid
                          %is_draft        = ls_new_part-%is_draft
                          MaintenanceOrder = lv_order_p
                          PartnerFunction  = 'VU'
                          PartnerCounter   = lv_base_p )
                 INTO TABLE mapped-zr_pm_order_partner.
        ENDIF.
        CLEAR lv_ihpa_exists.
      ENDLOOP.

      " Persist the highest counter into the LUW tracker
      IF lv_cnt_exists_p = abap_true.
        <pcnt>-max_part_n = lv_base_p.
      ELSE.
        INSERT VALUE #( maintenanceorder = lv_order_p
                        max_part_n       = lv_base_p )
               INTO TABLE gt_part_counters.
      ENDIF.

      CLEAR: lv_max_db_p, lv_max_draft_p, lv_max_db_n_p, lv_max_draft_n_p,
             lv_max_luw_p, lv_cnt_exists_p, lv_base_p, lv_objnr_en.

    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Component.
    DATA lv_operation TYPE zr_pm_order_comp-maintenanceorderoperation.

    LOOP AT entities_cba INTO DATA(ls_comp).

      SELECT SINGLE MIN( c~vornr )
        FROM afvc AS c INNER JOIN caufv AS o ON o~aufpl EQ c~aufpl
        WHERE o~aufnr EQ @ls_comp-%key-maintenanceorder
        INTO @lv_operation.

      SELECT SINGLE MaintenancePlanningPlant
        FROM zr_pm_order
        WHERE maintenanceorder = @ls_comp-%key-maintenanceorder
        INTO @DATA(lv_plant).

      LOOP AT ls_comp-%target INTO DATA(ls_target).
        APPEND INITIAL LINE TO gt_order_component_buffer ASSIGNING FIELD-SYMBOL(<new>).
        MOVE-CORRESPONDING ls_target TO <new>.
        <new>-MaintenanceOrder              = ls_comp-%key-MaintenanceOrder.
        <new>-updkz                         = 'I'.
        <new>-MaintenanceOrderOperation     = lv_operation.
        <new>-Plant                         = lv_plant.
        INSERT VALUE #( %cid                          = ls_target-%cid
                        MaintenanceOrder              = ls_comp-%key-MaintenanceOrder
                        MaintOrderComponentInternalID = ls_target-MaintOrderComponentInternalID
                        ReservationItem               = ls_target-ReservationItem )
          INTO TABLE mapped-component.
      ENDLOOP.

      IF lv_plant IS NOT INITIAL.
        UPDATE zpm_orderc_d
          SET plant = @lv_plant
          WHERE maintenanceorder = @ls_comp-%key-MaintenanceOrder
            AND plant            = ''.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Operation.
    LOOP AT entities_cba INTO DATA(ls_op).

      SELECT SINGLE MaintenancePlanningPlant
        FROM zr_pm_order
        WHERE maintenanceorder = @ls_op-%key-maintenanceorder
        INTO @DATA(lv_plant_op).

      LOOP AT ls_op-%target INTO DATA(ls_target).
        APPEND INITIAL LINE TO gt_order_operation_buffer ASSIGNING FIELD-SYMBOL(<new>).
        MOVE-CORRESPONDING ls_target TO <new>.
        <new>-MaintenanceOrder          = ls_op-%key-MaintenanceOrder.
        <new>-updkz                     = 'I'.
        <new>-MaintenanceOrderOperation = ls_target-MaintenanceOrderOperation.
        <new>-Plant                     = lv_plant_op.
        " mapped- already populated by earlynumbering_cba_Operation — do NOT insert again
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Partner.
    LOOP AT entities_cba INTO DATA(ls_part).

      LOOP AT ls_part-%target INTO DATA(ls_target).
        APPEND INITIAL LINE TO gt_order_partner_buffer ASSIGNING FIELD-SYMBOL(<new>).
        MOVE-CORRESPONDING ls_target TO <new>.
        <new>-MaintenanceOrder = ls_part-%key-MaintenanceOrder.
        <new>-PartnerFunction  = 'VU'.
        <new>-PartnerCounter   = ls_target-PartnerCounter.
        <new>-updkz            = 'I'.
        " mapped- already populated by earlynumbering_cba_Partner — do NOT insert again
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD sending_email.
    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          lo_sender       TYPE REF TO cl_sapuser_bcs,
          lo_recipient    TYPE REF TO cl_cam_address_bcs,
          lt_body         TYPE bcsy_text,
          lv_html_string  TYPE string,
          lv_app_url      TYPE string.

    " Uygulama linkinizi buraya tanımlayın (Fiori Launchpad veya uygulamanızın direkt URL'si)
    CASE sy-sysid.
      WHEN 'DS4'.
        lv_app_url = 'https://sistem-adresi.com/sap/bc/ui2/flp?#Uygulama-SemantikObje'.
      WHEN OTHERS.
        lv_app_url = 'https://sistem-adresi.com/sap/bc/ui2/flp?#Uygulama-SemantikObje'.
    ENDCASE.

    " HTML Body'sini oluşturma
    lv_html_string = |<html><body>| &&
                     | <p>{ is_mail-body }</p>| &&
                     | <br><br>| &&
                     | <p>Please click <a href="{ lv_app_url }">here</a> for open the document.</p>| &&
                     |</body></html>|.

    " String metni SOLI tablosuna (bcsy_text) çevirme
    lt_body = cl_document_bcs=>string_to_soli( lv_html_string ).

    TRY.
        lo_send_request = cl_bcs=>create_persistent( ).

        " i_type değerini RAW yerine HTM yapıyoruz
        lo_document = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_text    = lt_body
          i_subject = CONV so_obj_des( is_mail-subject )
        ).
        lo_send_request->set_document( lo_document ).

        " Gönderici oluşturma
        lo_sender = cl_sapuser_bcs=>create( sy-uname ).
        lo_send_request->set_sender( lo_sender ).

        " Alıcı email adresini bulma
        SELECT SINGLE smtp_addr INTO @DATA(lv_smtp)
          FROM adr6 AS a
          INNER JOIN usr21 AS u ON a~addrnumber EQ u~addrnumber AND a~persnumber EQ u~persnumber
          WHERE bname EQ @is_mail-uname.

        " Eğer kullanıcının mail adresi tanımlıysa ekle ve gönder
        IF lv_smtp IS NOT INITIAL.
          lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_smtp ).
          lo_send_request->add_recipient( lo_recipient ).

          lo_send_request->set_send_immediately( abap_true ).
          lo_send_request->send( ).
        ENDIF.

      CATCH cx_bcs INTO DATA(lx_bcs).
        " Hata yönetimi (Gerekirse lx_bcs->get_text( ) ile hata mesajını loglayabilirsiniz)
    ENDTRY.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.


  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).

*      DATA(ls_update) = VALUE lhc_zr_pm_order=>ty_order_update( maintenanceorder = ls_entity-MaintenanceOrder ).
*
*      " Check if Notification Text was changed
*      IF ls_entity-%control-ShortText = if_abap_behv=>mk-on.
*        ls_update-short_text   = ls_entity-ShortText.
*        ls_update-short_text_x = abap_true.
*      ENDIF.
*
*      " Check if Equipment was changed
*      IF ls_entity-%control-EquipmentNo = if_abap_behv=>mk-on.
*        ls_update-equipment   = ls_entity-EquipmentNo.
*        ls_update-equipment_x = abap_true.
*      ENDIF.
*
*      " Check if Workcenter was changed
*      IF ls_entity-%control-Workcenter = if_abap_behv=>mk-on.
*        " Convert the Workcenter string back to Internal ID just like we did in Create
*        IF ls_entity-Workcenter IS NOT INITIAL.
*          SELECT SINGLE workcenterinternalid FROM i_workcenter
*            WHERE workcenter = @ls_entity-Workcenter
*            INTO @ls_update-wkctr.
*        ENDIF.
*        ls_update-wkctr_x = abap_true.
*      ENDIF.
*
*      " Only append to the buffer if at least one field was actually changed
*      IF ls_update-short_text_x = abap_true OR
*         ls_update-equipment_x  = abap_true OR
*         ls_update-wkctr_x      = abap_true.
*
*        APPEND ls_update TO lhc_zr_pm_notif=>gt_notif_update_buffer.
*
*      ENDIF.

*      IF ls_entity-%control-BasicCode = if_abap_behv=>mk-on.
*        ls_update-dl_code   = ls_entity-BasicCode.
*        ls_update-dl_code_x = abap_true.
*      ENDIF.
*
*      IF ls_entity-%control-DetailCode = if_abap_behv=>mk-on.
*        ls_update-d_code   = ls_entity-DetailCode.
*        ls_update-d_code_x = abap_true.
*      ENDIF.

    ENDLOOP.
  ENDMETHOD.



  METHOD read.
    IF keys IS NOT INITIAL.
      SELECT * FROM zr_pm_order
        FOR ALL ENTRIES IN @keys
        WHERE maintenanceorder = @keys-maintenanceorder
        INTO TABLE @DATA(lt_active_data).
    ENDIF.
    IF is_supervisor( ) = abap_false.

      " Teknisyen: sadece partner tablosunda kendisi olan siparişleri göster
      " IHPA: objnr = 'OR' + aufnr, parvw = 'VU' (Responsible Person)
      DATA lt_filtered LIKE lt_active_data.

      LOOP AT lt_active_data INTO DATA(ls_check).
        IF ls_check-currentuser EQ 'X' OR is_notifier( iv_aufnr = ls_check-maintenanceorder ).
          APPEND ls_check TO lt_filtered.
        ENDIF.
      ENDLOOP.

      " Filtrelenmiş listeyi kullan
      lt_active_data = lt_filtered.

    ENDIF.
    LOOP AT lt_active_data INTO DATA(ls_active).
      INSERT VALUE #(
          %tky  = VALUE #( maintenanceorder = ls_active-maintenanceorder )
          %data = CORRESPONDING #( ls_active )
      ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    DATA: lv_user TYPE symsgv.

    LOOP AT keys INTO DATA(key).
      CALL FUNCTION 'ENQUEUE_ESORDER'
        EXPORTING
          aufnr          = key-maintenanceorder
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.

      IF sy-subrc <> 0.
        lv_user = sy-msgv1.
        IF lv_user IS INITIAL.
          lv_user = 'another user'.
        ENDIF.

        APPEND VALUE #( maintenanceorder = key-maintenanceorder
                        %fail-cause      = if_abap_behv=>cause-locked
                      ) TO failed-zr_pm_order.

        APPEND new_message( id       = '00'
                            number   = '001'
                            severity = if_abap_behv_message=>severity-error
                            v1       = 'Locked by user:'
                            v2       = lv_user )
               TO reported-%other.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Component.
  ENDMETHOD.

  METHOD rba_Operation.
  ENDMETHOD.


  " ════════════════════════════════════════════════════════════════════
  " GET_INSTANCE_FEATURES
  " ════════════════════════════════════════════════════════════════════
  METHOD get_instance_features.
    DATA(lv_is_sup) = is_supervisor( ).
    DATA(lv_is_tec) = is_technician( ).

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_is_notf) = is_notifier( ls_key-maintenanceorder ).
      DATA(lv_status) = get_user_status( ls_key-maintenanceorder ).

      DATA(lv_hidden) = if_abap_behv=>fc-o-disabled.

      DATA(lv_start_fc)   = lv_hidden.
      DATA(lv_confirm_fc) = lv_hidden.
      DATA(lv_approve_fc) = lv_hidden.

      CASE lv_status.
        WHEN 'INIT' .
          IF lv_is_sup = abap_true OR lv_is_tec = abap_true.
            lv_start_fc = if_abap_behv=>fc-o-enabled.
          ENDIF.
        WHEN 'STARTED' OR 'REJECT'.
          IF lv_is_sup = abap_true OR lv_is_tec = abap_true.
            lv_confirm_fc = if_abap_behv=>fc-o-enabled.
          ENDIF.
        WHEN 'CONFIRMED'.
          IF lv_is_tec = abap_false OR lv_is_notf = abap_true OR lv_is_sup = abap_true.
            lv_approve_fc = if_abap_behv=>fc-o-enabled.
          ENDIF.
        WHEN 'APPROVED'.
          IF lv_is_tec = abap_false OR lv_is_notf = abap_true OR lv_is_sup = abap_true.
            lv_approve_fc = if_abap_behv=>fc-o-enabled.
          ENDIF.
      ENDCASE.

      APPEND VALUE #(
        maintenanceorder      = ls_key-maintenanceorder
        %action-start_order   = lv_start_fc
        %action-confirm_order = lv_confirm_fc
        %action-approve_order = lv_approve_fc
        %action-reject_order  = lv_approve_fc
      ) TO result.

    ENDLOOP.
  ENDMETHOD.

  " ════════════════════════════════════════════════════════════════════
  " ACTION: START ORDER
  " Validasyon + buffer + result doldur (CALL FUNCTION YOK)
  " ════════════════════════════════════════════════════════════════════
  METHOD start_order.
    READ ENTITIES OF zr_pm_order IN LOCAL MODE
      ENTITY zr_pm_order
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).

      DATA(lv_aufnr) = ls_order-maintenanceorder.

      " Validasyon
      DATA(lv_status) = get_user_status( lv_aufnr ).
      IF lv_status <> 'INIT'.
        APPEND VALUE #(
          maintenanceorder = lv_aufnr
          %fail-cause      = if_abap_behv=>cause-unspecific
        ) TO failed-zr_pm_order.

        APPEND new_message( id       = '00'
                            number   = '001'
                            severity = if_abap_behv_message=>severity-error
                            v1       = 'Order is not in INIT status:'
                            v2       = lv_aufnr )
               TO reported-%other.
        CONTINUE.
      ENDIF.

      " Buffer'a yaz
      APPEND VALUE ty_order_start(
        maintenanceorder        = lv_aufnr
        NotificationCreatedUser = ls_order-NotificationCreatedUser
        notificationnumber      = ls_order-MaintenanceNotification
        maintordbasicstartdate  = sy-datum
        maintordbasicstarttime  = sy-uzeit
      ) TO gt_order_start_buffer.

      " Result doldur
      INSERT VALUE #(
        maintenanceorder = lv_aufnr
        %param           = CORRESPONDING #( ls_order )
      ) INTO TABLE result.

      " Başarı mesajı
      APPEND new_message( id       = '00'
                          number   = '001'
                          severity = if_abap_behv_message=>severity-success
                          v1       = 'Order started:'
                          v2       = lv_aufnr )
             TO reported-%other.

    ENDLOOP.
  ENDMETHOD.

  " ════════════════════════════════════════════════════════════════════
  " ACTION: CONFIRM ORDER (Popup)
  " ════════════════════════════════════════════════════════════════════
  METHOD confirm_order.

    READ ENTITIES OF zr_pm_order IN LOCAL MODE
      ENTITY zr_pm_order
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).
      DATA(lv_aufnr) = ls_order-maintenanceorder.

      DATA(lv_status) = get_user_status( lv_aufnr ).
      IF lv_status <> 'STARTED' AND lv_status <> 'REJECT' .
        APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
        APPEND new_message( id = '00' number = '001' severity = if_abap_behv_message=>severity-error
                            v1 = 'Order is not in STARTED or REJECT status:' v2 = lv_aufnr ) TO reported-%other.
        CONTINUE.
      ENDIF.

      " Parametre okuması için ilgili anahtarı bul
      READ TABLE keys INTO DATA(ls_key) WITH KEY maintenanceorder = lv_aufnr.
      "date&time validation
      DATA(lv_conf_date) = COND d( WHEN ls_key-%param-ConfEndDate IS INITIAL THEN sy-datum ELSE ls_key-%param-ConfEndDate ).
      DATA(lv_conf_time) = COND t( WHEN ls_key-%param-ConfEndTime IS INITIAL THEN sy-uzeit ELSE ls_key-%param-ConfEndTime ).

      " 1. Validation: Malfunction start / notification creation date and time check
      " Malfunction start date/time (notification creation date/time)
      DATA(lv_notif_date) = ls_order-NotifCreationDate.
      DATA(lv_notif_time) = ls_order-NotifCreationTime.

      IF lv_notif_date IS INITIAL.
        SELECT SINGLE CreationDate, CreationTime
          FROM I_MaintenanceNotification
          WHERE MaintenanceNotification = @ls_order-MaintenanceNotification
          INTO ( @lv_notif_date, @lv_notif_time ).
      ENDIF.

      IF lv_notif_date IS NOT INITIAL.
        IF lv_conf_date < lv_notif_date OR ( lv_conf_date = lv_notif_date AND lv_conf_time < lv_notif_time ).
          APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
          APPEND new_message( id       = '00'
                              number   = '001'
                              severity = if_abap_behv_message=>severity-error
                              v1       = 'Confirmation date/time cannot be before'
                              v2       = 'malfunction start date/time' ) TO reported-%other.
          CONTINUE.
        ENDIF.
      ENDIF.

      " 2. Validation: Future date/time check (cannot be greater than current date/time)
      IF lv_conf_date > sy-datum OR ( lv_conf_date = sy-datum AND lv_conf_time > sy-uzeit ).
        APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
        APPEND new_message( id       = '00'
                            number   = '001'
                            severity = if_abap_behv_message=>severity-error
                            v1       = 'Confirmation date/time cannot be later'
                            v2       = 'than current date/time' ) TO reported-%other.
        CONTINUE.
      ENDIF.
      "date&time validation
      " Buffer'a yaz
      APPEND VALUE ty_order_confirm(
        maintenanceorder        = lv_aufnr
        NotificationCreatedUser = ls_order-NotificationCreatedUser
        notificationnumber      = ls_order-MaintenanceNotification
        conf_start_date         = ls_order-MaintOrdBasicStartDate
        conf_start_time         = ls_order-MaintOrdBasicStartTime
        confirmnote             = ls_key-%param-Description
        conf_end_date           = lv_conf_date
        conf_end_time           = lv_conf_time
      ) TO gt_order_confirm_buffer.

      INSERT VALUE #(
        maintenanceorder = lv_aufnr
        %param           = CORRESPONDING #( ls_order )
      ) INTO TABLE result.

      APPEND new_message( id = '00' number = '001' severity = if_abap_behv_message=>severity-success
                          v1 = 'Confirmation created:' v2 = lv_aufnr ) TO reported-%other.
    ENDLOOP.
  ENDMETHOD.

  " ════════════════════════════════════════════════════════════════════
  " ACTION: APPROVE ORDER (Popup)
  " ════════════════════════════════════════════════════════════════════
  METHOD approve_order.
    READ ENTITIES OF zr_pm_order IN LOCAL MODE
          ENTITY zr_pm_order
          ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).
      DATA(lv_aufnr) = ls_order-maintenanceorder.

      DATA(lv_status) = get_user_status( lv_aufnr ).
      IF lv_status <> 'CONFIRMED'.
        APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
        APPEND new_message( id = '00' number = '001' severity = if_abap_behv_message=>severity-error
                            v1 = 'Order is not in CONFIRMED status:' v2 = lv_aufnr ) TO reported-%other.
        CONTINUE.
      ENDIF.

      READ TABLE keys INTO DATA(ls_key) WITH KEY maintenanceorder = lv_aufnr.

      DATA(lv_aprv_date) = ls_key-%param-ActualEndDate.
      DATA(lv_aprv_time) = ls_key-%param-ActualEndTime.

      " If approval date/time provided, validate against malfunction start and future timestamp
      IF lv_aprv_date IS NOT INITIAL.
        DATA(lv_aprv_notif_date) = ls_order-NotifCreationDate.
        DATA(lv_aprv_notif_time) = ls_order-NotifCreationTime.

        IF lv_aprv_notif_date IS INITIAL.
          SELECT SINGLE CreationDate, CreationTime
            FROM I_MaintenanceNotification
            WHERE MaintenanceNotification = @ls_order-MaintenanceNotification
            INTO ( @lv_aprv_notif_date, @lv_aprv_notif_time ).
        ENDIF.

        IF lv_aprv_notif_date IS NOT INITIAL.
          IF lv_aprv_date < lv_aprv_notif_date OR ( lv_aprv_date = lv_aprv_notif_date AND lv_aprv_time < lv_aprv_notif_time ).
            APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
            APPEND new_message( id       = '00'
                                number   = '001'
                                severity = if_abap_behv_message=>severity-error
                                v1       = 'Approval end date/time cannot be before'
                                v2       = 'malfunction start date/time' ) TO reported-%other.
            CONTINUE.
          ENDIF.
        ENDIF.

        IF lv_aprv_date > sy-datum OR ( lv_aprv_date = sy-datum AND lv_aprv_time > sy-uzeit ).
          APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
          APPEND new_message( id       = '00'
                              number   = '001'
                              severity = if_abap_behv_message=>severity-error
                              v1       = 'Approval end date/time cannot be later'
                              v2       = 'than current date/time' ) TO reported-%other.
          CONTINUE.
        ENDIF.
      ENDIF.

      APPEND VALUE ty_order_approve(
        _ar                = 'A'
        maintenanceorder   = lv_aufnr
        notificationnumber = ls_order-MaintenanceNotification
        approvenote             = ls_key-%param-Description
        actual_end_date    = lv_aprv_date
        actual_end_time    = lv_aprv_time
      ) TO gt_order_approve_buffer.

      INSERT VALUE #( maintenanceorder = lv_aufnr %param = CORRESPONDING #( ls_order ) ) INTO TABLE result.

      APPEND new_message( id = '00' number = '001' severity = if_abap_behv_message=>severity-success
                          v1 = 'Order approved:' v2 = lv_aufnr ) TO reported-%other.
    ENDLOOP.
  ENDMETHOD.

  METHOD reject_order.
    READ ENTITIES OF zr_pm_order IN LOCAL MODE
          ENTITY zr_pm_order
          ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT DATA(lt_orders).

    LOOP AT lt_orders INTO DATA(ls_order).
      DATA(lv_aufnr) = ls_order-maintenanceorder.

      DATA(lv_status) = get_user_status( lv_aufnr ).
      IF lv_status <> 'CONFIRMED'.
        APPEND VALUE #( maintenanceorder = lv_aufnr %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-zr_pm_order.
        APPEND new_message( id = '00' number = '001' severity = if_abap_behv_message=>severity-error
                            v1 = 'Order is not in CONFIRMED status:' v2 = lv_aufnr ) TO reported-%other.
        CONTINUE.
      ENDIF.
      READ TABLE keys INTO DATA(ls_key) WITH KEY maintenanceorder = lv_aufnr.

      APPEND VALUE ty_order_approve(
        _ar                = 'R'
        maintenanceorder   = lv_aufnr
        notificationnumber = ls_order-MaintenanceNotification
        approvenote        = ls_key-%param-Description
      ) TO gt_order_approve_buffer.

      INSERT VALUE #( maintenanceorder = lv_aufnr %param = CORRESPONDING #( ls_order ) ) INTO TABLE result.

      APPEND new_message( id = '00' number = '001' severity = if_abap_behv_message=>severity-success
                          v1 = 'Order Rejected:' v2 = lv_aufnr ) TO reported-%other.
    ENDLOOP.
  ENDMETHOD.



*  METHOD release_order.
*
*    LOOP AT keys INTO DATA(ls_key).
*
*      DATA(lv_aufnr) = ls_key-maintenanceorder.
*
*      SELECT SINGLE * FROM zr_pm_order
*        WHERE maintenanceorder = @lv_aufnr
*        INTO @DATA(ls_data_c).
*
*
*      DATA(lv_status) = get_user_status( lv_aufnr ).
*      IF lv_status <> 'CONFIRMED'.
*        APPEND VALUE #(
*          maintenanceorder   = lv_aufnr
*          %fail-cause        = if_abap_behv=>cause-unspecific
*        ) TO failed-zr_pm_order.
*
*        APPEND new_message( id       = '00'
*                            number   = '001'
*                            severity = if_abap_behv_message=>severity-error
*                            v1       = 'Order is not in CONFIRMED status:'
*                            v2       = lv_aufnr )
*               TO reported-%other.
*        CONTINUE.
*      ENDIF.
*
*      " Buffer'a yaz
*      APPEND VALUE ty_order_approve(
*        _ar              = 'Q'
*        maintenanceorder = lv_aufnr
*        notificationnumber = ls_data_c-MaintenanceNotification
*      ) TO gt_order_approve_buffer.
*
*      " Result doldur
*      SELECT SINGLE * FROM zr_pm_order
*        WHERE maintenanceorder = @lv_aufnr
*        INTO @DATA(ls_data_a).
*
*      INSERT VALUE #(
*        maintenanceorder = lv_aufnr
*        %param           = CORRESPONDING #( ls_data_a )
*      ) INTO TABLE result.
*
*      APPEND new_message( id       = '00'
*                          number   = '001'
*                          severity = if_abap_behv_message=>severity-success
*                          v1       = 'Order approved:'
*                          v2       = lv_aufnr )
*             TO reported-%other.
*
*    ENDLOOP.
*  ENDMETHOD.


  " ════════════════════════════════════════════════════════════════════
  " PRIVATE: is_notifier
  " ════════════════════════════════════════════════════════════════════
  METHOD is_notifier.
    SELECT COUNT(*) FROM i_notification
      WHERE CreatedByUser = @sy-uname
        AND OrderID       = @iv_aufnr
      INTO @DATA(lv_count).

    rv_result = COND #( WHEN lv_count > 0 THEN abap_true ELSE abap_false ).
  ENDMETHOD.

  METHOD is_supervisor.

    AUTHORITY-CHECK OBJECT 'ZPM_NOTIF'
    ID 'ZPM_ROLE' FIELD 'SUP'
    ID 'ACTVT'    DUMMY.


    IF sy-subrc = 0.
      rv_result = abap_true.
    ELSE.
      rv_result = abap_false.
    ENDIF.

  ENDMETHOD.

  METHOD is_technician.

    AUTHORITY-CHECK OBJECT 'ZPM_NOTIF'
    ID 'ZPM_ROLE' FIELD 'TEC'
    ID 'ACTVT'    DUMMY.


    IF sy-subrc = 0.
      rv_result = abap_true.
    ELSE.
      rv_result = abap_false.
    ENDIF.

  ENDMETHOD.

  " ════════════════════════════════════════════════════════════════════
  " PRIVATE: Sipariş kullanıcı statüsünü oku
  " ════════════════════════════════════════════════════════════════════
  METHOD get_user_status.

    DATA: lv_objnr TYPE j_objnr.
    lv_objnr = |OR{ iv_aufnr }|.

    SELECT j~stat, t~txt04
      FROM jest AS j
      INNER JOIN tj30t AS t
        ON  t~stsma = 'ZALMPM'
        AND t~estat = j~stat
        AND t~spras = @sy-langu
      WHERE j~objnr = @lv_objnr
        AND j~inact = @abap_false
        AND j~stat LIKE 'E%'
      INTO TABLE @DATA(lt_status).

    LOOP AT lt_status INTO DATA(ls_stat).
      CASE ls_stat-txt04.
        WHEN 'APPR'.
          rv_status = 'APPROVED'.  RETURN.
        WHEN 'CONF'.
          rv_status = 'CONFIRMED'. RETURN.
        WHEN 'STRT'.
          rv_status = 'STARTED'.   RETURN.
        WHEN 'INIT'.
          rv_status = 'INIT'.      RETURN.
        WHEN 'REJE'.
          rv_status = 'REJECT'.      RETURN.
      ENDCASE.
    ENDLOOP.

    rv_status = 'INIT'.

  ENDMETHOD.

  METHOD rba_Partner.
  ENDMETHOD.



ENDCLASS.


" =====================================================================
" PARTNER HANDLER
" =====================================================================
CLASS lhc_zr_pm_order_partner DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ zr_pm_order_partner RESULT result.
    METHODS rba_Order FOR READ
      IMPORTING keys_rba FOR READ zr_pm_order_partner\_Order FULL result_requested RESULT result LINK association_links.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_pm_order_partner.
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zr_pm_order_partner.
ENDCLASS.

CLASS lhc_zr_pm_order_partner IMPLEMENTATION.
  METHOD read.
  ENDMETHOD.

  METHOD rba_Order.
  ENDMETHOD.

  METHOD update.
    " Only update draft rows for truly new partners (counter not yet in IHPA).
    " Existing partners have no update path — user must delete and re-add.
    LOOP AT entities INTO DATA(ls_upd).
      DATA lv_exists TYPE abap_bool.
      SELECT SINGLE @abap_true FROM ihpa
        WHERE objnr   = @( CONV j_objnr( |OR{ ls_upd-MaintenanceOrder ALPHA = IN }| ) )
          AND counter = @ls_upd-PartnerCounter
        INTO @lv_exists.
      IF lv_exists = abap_true.
        APPEND VALUE #(
          %tky = ls_upd-%tky
          %msg = new_message( id = '00' number = '001'
                   severity = if_abap_behv_message=>severity-error
                   v1 = 'Partner already saved - changes not allowed.'
                   v2 = 'Discard the draft and delete/re-add the partner.' )
        ) TO reported-zr_pm_order_partner.
        APPEND VALUE #( %tky        = ls_upd-%tky
                        %fail-cause = if_abap_behv=>cause-unspecific )
          TO failed-zr_pm_order_partner.
        CONTINUE.
      ENDIF.
      DELETE lhc_ZR_PM_ORDER=>gt_order_partner_buffer
        WHERE MaintenanceOrder = ls_upd-MaintenanceOrder
          AND PartnerCounter   = ls_upd-PartnerCounter.
      APPEND INITIAL LINE TO lhc_ZR_PM_ORDER=>gt_order_partner_buffer ASSIGNING FIELD-SYMBOL(<upd>).
      MOVE-CORRESPONDING ls_upd TO <upd>.
      <upd>-updkz = 'I'.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_deleted_part).
      DATA(lv_objnr) = CONV j_objnr( |OR{ ls_deleted_part-MaintenanceOrder ALPHA = IN }| ).
      DATA lv_parnr TYPE ihpa-parnr.
      SELECT SINGLE parnr FROM ihpa
        WHERE objnr   = @lv_objnr
          AND counter = @ls_deleted_part-PartnerCounter
        INTO @lv_parnr.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
          MaintenanceOrder = ls_deleted_part-MaintenanceOrder
          PartnerFunction  = ls_deleted_part-PartnerFunction
          PartnerCounter   = ls_deleted_part-PartnerCounter
          Partner          = lv_parnr
          updkz            = 'D'
      ) TO lhc_ZR_PM_ORDER=>gt_order_partner_buffer.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


" =====================================================================
" COMPONENT HANDLER
" =====================================================================
CLASS lhc_ZR_PM_ORDER_COMP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
*    METHODS earlynumbering_cba_Component FOR NUMBERING
*      IMPORTING entities FOR CREATE zr_pm_order_comp.
    METHODS read FOR READ
      IMPORTING keys FOR READ component RESULT result.
    METHODS rba_Order FOR READ
      IMPORTING keys_rba FOR READ component\_Order FULL result_requested RESULT result LINK association_links.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE component.
    METHODS delete_component FOR MODIFY
      IMPORTING keys FOR DELETE component.


ENDCLASS.

CLASS lhc_ZR_PM_ORDER_COMP IMPLEMENTATION.
  METHOD read.
    " Draft modunda framework kendi okuma işlemini yapar
    " Özel bir filtreleme gerekmiyorsa boş bırakılabilir
  ENDMETHOD.
  METHOD rba_Order.
    " Association okuma - framework yönetir
  ENDMETHOD.
  METHOD update.
    "BREAK-POINT.
    LOOP AT entities INTO DATA(ls_update).

      " Add it to the global buffer with the 'Delete' flag
      DELETE lhc_ZR_PM_ORDER=>gt_order_component_buffer WHERE ReservationItem = ls_update-ReservationItem.
      APPEND INITIAL LINE TO lhc_ZR_PM_ORDER=>gt_order_component_buffer ASSIGNING FIELD-SYMBOL(<update>).
      MOVE-CORRESPONDING ls_update TO <update>.
      <update>-updkz = 'U'.
    ENDLOOP.

  ENDMETHOD.

  METHOD delete_component.
    " This method is called when the user removes a partner and clicks Save.

    LOOP AT keys INTO DATA(ls_deleted_comp).

      " Add it to the global buffer with the 'Delete' flag
      APPEND VALUE #(
          MaintenanceOrder              = ls_deleted_comp-MaintenanceOrder
          MaintOrderComponentInternalID = ls_deleted_comp-MaintOrderComponentInternalID
          ReservationItem               = ls_deleted_comp-ReservationItem

          updkz                         = 'D' " D = Delete
      ) TO lhc_ZR_PM_ORDER=>gt_order_component_buffer.

    ENDLOOP.

  ENDMETHOD.
*  METHOD earlynumbering_cba_Component.
*    LOOP AT entities INTO DATA(ls_entity).
*
*      " UUID üret
*      DATA(lv_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
*
*      " MAPPED'e yaz - bu zorunlu
*      APPEND VALUE #(
*        %cid                               = ls_entity-%cid
*        %is_draft                          = ls_entity-%is_draft
*        %key-MaintenanceOrder              = ls_entity-MaintenanceOrder
*        %key-MaintOrderComponentInternalID = lv_uuid
*      ) TO mapped-zr_pm_order_comp.
*
*    ENDLOOP.
*  ENDMETHOD.
ENDCLASS.


" =====================================================================
" OPERATION HANDLER
" =====================================================================
CLASS lhc_ZR_PM_ORDER_OPERATION DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ zr_pm_order_operation RESULT result.
    METHODS rba_Order FOR READ
      IMPORTING keys_rba FOR READ zr_pm_order_operation\_Order FULL result_requested RESULT result LINK association_links.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zr_pm_order_operation.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zr_pm_order_operation.
ENDCLASS.

CLASS lhc_ZR_PM_ORDER_OPERATION IMPLEMENTATION.
  METHOD read.    ENDMETHOD.
  METHOD rba_Order. ENDMETHOD.
  METHOD update.
    LOOP AT entities INTO DATA(ls_update).
      DATA(lv_order) = ls_update-%key-maintenanceorder.
      DATA(lv_op)    = ls_update-%key-maintenanceorderoperation.

      CHECK lv_op IS NOT INITIAL.

      SELECT SINGLE aufpl FROM caufv
        WHERE aufnr = @lv_order INTO @DATA(lv_aufpl_upd).
      DATA(lv_op_exists_in_db) = abap_false.
      IF sy-subrc = 0.
        SELECT SINGLE vornr FROM afvc
          WHERE aufpl = @lv_aufpl_upd
            AND vornr = @lv_op
          INTO @DATA(lv_vornr_chk).
        IF sy-subrc = 0.
          lv_op_exists_in_db = abap_true.
        ENDIF.
      ENDIF.

      DELETE lhc_ZR_PM_ORDER=>gt_order_operation_buffer
        WHERE MaintenanceOrder          = lv_order
          AND MaintenanceOrderOperation = lv_op.

      APPEND INITIAL LINE TO lhc_ZR_PM_ORDER=>gt_order_operation_buffer ASSIGNING FIELD-SYMBOL(<update>).
      <update>-MaintenanceOrder          = lv_order.
      <update>-MaintenanceOrderOperation = lv_op.
      <update>-updkz = COND #( WHEN lv_op_exists_in_db = abap_true THEN 'U' ELSE 'I' ).

      IF ls_update-%control-OperationDescription = if_abap_behv=>mk-on.
        <update>-OperationDescription = ls_update-OperationDescription.
      ENDIF.
      IF ls_update-%control-Plant = if_abap_behv=>mk-on.
        <update>-Plant = ls_update-Plant.
      ENDIF.
      IF ls_update-%control-WorkCenter = if_abap_behv=>mk-on.
        <update>-WorkCenter = ls_update-WorkCenter.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.

    LOOP AT keys INTO DATA(ls_deleted_ord).

      " Add it to the global buffer with the 'Delete' flag
      APPEND VALUE #(
          MaintenanceOrder          = ls_deleted_ord-MaintenanceOrder
          MaintenanceOrderOperation = ls_deleted_ord-MaintenanceOrderOperation
          MaintOrderRoutingNumber   = ls_deleted_ord-MaintOrderRoutingNumber
          updkz                     = 'D'     " D = Delete
      ) TO lhc_ZR_PM_ORDER=>gt_order_operation_buffer.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


" =====================================================================
" SAVER CLASS — TÜM BAPI ÇAĞRILARI BURADA
" =====================================================================
CLASS lsc_ZR_PM_ORDER DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
    METHODS cleanup_finalize  REDEFINITION.
ENDCLASS.

CLASS lsc_ZR_PM_ORDER IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
    " Partner mutex: cannot mix ADD and DELETE in one save
    DATA(lv_has_add_p) = abap_false.
    DATA(lv_has_del_p) = abap_false.
    LOOP AT lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_pbuf).
      IF ls_pbuf-updkz = 'I'. lv_has_add_p = abap_true. ENDIF.
      IF ls_pbuf-updkz = 'D'. lv_has_del_p = abap_true. ENDIF.
    ENDLOOP.
    IF lv_has_add_p = abap_true AND lv_has_del_p = abap_true.
      READ TABLE lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_ph) INDEX 1.
      APPEND VALUE #(
        %tky = VALUE #( maintenanceorder = ls_ph-MaintenanceOrder )
        %msg = new_message( id = '00' number = '001'
                 severity = if_abap_behv_message=>severity-error
                 v1 = 'Cannot add and delete partners in one save.'
                 v2 = 'Discard draft, then do only one operation.' )
      ) TO reported-zr_pm_order_partner.
      APPEND VALUE #( %tky          = VALUE #( maintenanceorder = ls_ph-MaintenanceOrder )
                      %fail-cause   = if_abap_behv=>cause-unspecific )
        TO failed-zr_pm_order_partner.
    ENDIF.

    " Cross-section mutex: only one section (component / operation / partner) per save
    DATA(lv_has_comp) = abap_false.
    DATA(lv_has_op)   = abap_false.
    DATA(lv_has_part) = abap_false.
    LOOP AT lhc_zr_pm_order=>gt_order_component_buffer INTO DATA(ls_comp_chk).
      lv_has_comp = abap_true. EXIT.
    ENDLOOP.
    LOOP AT lhc_zr_pm_order=>gt_order_operation_buffer INTO DATA(ls_op_chk).
      lv_has_op = abap_true. EXIT.
    ENDLOOP.
    LOOP AT lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_pt_chk).
      lv_has_part = abap_true. EXIT.
    ENDLOOP.
    DATA(lv_section_count) = 0.
    IF lv_has_comp = abap_true. lv_section_count += 1. ENDIF.
    IF lv_has_op   = abap_true. lv_section_count += 1. ENDIF.
    IF lv_has_part = abap_true. lv_section_count += 1. ENDIF.
    IF lv_section_count > 1.
      DATA(ls_mutex_order) = CONV aufnr( '' ).
      DATA ls_co_buf TYPE lhc_zr_pm_order=>ty_order_comp.
      READ TABLE lhc_zr_pm_order=>gt_order_component_buffer INTO ls_co_buf INDEX 1.
      IF sy-subrc = 0.
        ls_mutex_order = ls_co_buf-MaintenanceOrder.
      ELSE.
        DATA ls_op_buf TYPE lhc_zr_pm_order=>ty_order_op.
        READ TABLE lhc_zr_pm_order=>gt_order_operation_buffer INTO ls_op_buf INDEX 1.
        IF sy-subrc = 0.
          ls_mutex_order = ls_op_buf-MaintenanceOrder.
        ELSE.
          READ TABLE lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_pt_buf) INDEX 1.
          ls_mutex_order = ls_pt_buf-MaintenanceOrder.
        ENDIF.
      ENDIF.
      APPEND VALUE #(
        %tky = VALUE #( maintenanceorder = ls_mutex_order )
        %msg = new_message( id = '00' number = '001'
                 severity = if_abap_behv_message=>severity-error
                 v1 = 'Only one section per save (comp/op/partner).'
                 v2 = 'Discard draft and save each section separately.' )
      ) TO reported-zr_pm_order.
      APPEND VALUE #( %tky        = VALUE #( maintenanceorder = ls_mutex_order )
                      %fail-cause = if_abap_behv=>cause-unspecific )
        TO failed-zr_pm_order.
    ENDIF.
  ENDMETHOD.

  METHOD save.

    " ──────────────────────────────────────────────
    " 2) START: Başlangıç tarihi + Statü → STARTED
    " ──────────────────────────────────────────────
    LOOP AT lhc_zr_pm_order=>gt_order_start_buffer INTO DATA(ls_start).

      DATA: lt_methods_s   TYPE TABLE OF bapi_alm_order_method,
            lt_header_s    TYPE TABLE OF bapi_alm_order_headers_i,
            lt_header_up_s TYPE TABLE OF bapi_alm_order_headers_up,
            lt_return_s    TYPE TABLE OF bapiret2.

      CLEAR: lt_methods_s, lt_header_s, lt_header_up_s, lt_return_s.

      APPEND VALUE bapi_alm_order_method(
        refnumber = '000001' objecttype = 'HEADER'
        method    = 'CHANGE' objectkey  = ls_start-maintenanceorder
      ) TO lt_methods_s.
      APPEND VALUE bapi_alm_order_method(
        refnumber = '000002' objecttype = ''
        method    = 'SAVE'   objectkey  = ls_start-maintenanceorder
      ) TO lt_methods_s.

      APPEND VALUE bapi_alm_order_headers_i(
        orderid    = ls_start-maintenanceorder
        start_date = ls_start-maintordbasicstartdate
        basicstart = ls_start-maintordbasicstarttime
        sched_type = '5'
        "finish_date = '00000000'
        "basic_fin   = '000000'
      ) TO lt_header_s.

      APPEND VALUE bapi_alm_order_headers_up(
        orderid     = ls_start-maintenanceorder
        start_date  = abap_true
        basicstart  = abap_true
        sched_type  = abap_true
        finish_date = abap_true
        basic_fin   = abap_true
      ) TO lt_header_up_s.

      CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
        TABLES
          it_methods   = lt_methods_s
          it_header    = lt_header_s
          it_header_up = lt_header_up_s
          return       = lt_return_s.

      DATA(lv_err_s) = abap_false.
      LOOP AT lt_return_s INTO DATA(ls_return_s) WHERE type CA 'EA'.
        lv_err_s = abap_true.
        APPEND VALUE #(
          %tky = VALUE #( maintenanceorder = ls_start-maintenanceorder )
          %msg = new_message(
                          id               = ls_return_s-id
                          number           = ls_return_s-number
                          severity         = if_abap_behv_message=>severity-error
                          v1               = ls_return_s-message_v1
                          v2               = ls_return_s-message_v2
                          v3               = ls_return_s-message_v3
                          v4               = ls_return_s-message_v4 )
        ) TO reported-zr_pm_order.

      ENDLOOP.

*      IF lv_err_s = abap_false.
      DATA(lv_objnr_s) = CONV j_objnr( |OR{ ls_start-maintenanceorder }| ).
      CALL FUNCTION 'STATUS_CHANGE_EXTERN'
        EXPORTING
          objnr               = lv_objnr_s
          user_status         = 'E0002'
        EXCEPTIONS
          object_not_found    = 1
          status_inconsistent = 2
          status_not_allowed  = 3
          OTHERS              = 4.
*      ENDIF.


    ENDLOOP.
    CLEAR lhc_zr_pm_order=>gt_order_start_buffer.


    " ──────────────────────────────────────────────
    " 3) CONFIRM: Teyit + Statü → CONFIRMED
    " ──────────────────────────────────────────────

    IF lhc_zr_pm_order=>gt_order_confirm_buffer IS NOT INITIAL.
      SELECT maintenanceorder, maintenanceorderoperation
        FROM i_maintenanceorderoperation
        FOR ALL ENTRIES IN @lhc_zr_pm_order=>gt_order_confirm_buffer
        WHERE maintenanceorder = @lhc_zr_pm_order=>gt_order_confirm_buffer-maintenanceorder
        INTO TABLE @DATA(lt_operations).
    ENDIF.
    LOOP AT lhc_zr_pm_order=>gt_order_confirm_buffer INTO DATA(ls_conf).

      DATA: ls_return_c    TYPE bapiret2,
            lt_alm_ret     TYPE TABLE OF bapi_alm_return,
            lt_timetickets TYPE TABLE OF bapi_alm_timeconfirmation,
            ls_timeticket  TYPE bapi_alm_timeconfirmation.

      CLEAR: ls_return_c, lt_timetickets, lt_alm_ret.

      DATA(lv_operation) = '0010'. " Varsayılan
      READ TABLE lt_operations INTO DATA(ls_op) WITH KEY maintenanceorder = ls_conf-maintenanceorder.
      IF sy-subrc = 0.
        lv_operation = ls_op-maintenanceorderoperation.
      ENDIF.
      IF sy-subrc <> 0.
        lv_operation = '0010'.
      ENDIF.

      CLEAR ls_timeticket.
      ls_timeticket-fin_conf        = abap_true.
      ls_timeticket-orderid         = ls_conf-maintenanceorder.
      ls_timeticket-operation       = lv_operation.
      ls_timeticket-conf_text       = 'Confirmed via Fiori'.
      ls_timeticket-exec_start_date = ls_conf-conf_start_date.
      ls_timeticket-exec_start_time = ls_conf-conf_start_time.
      ls_timeticket-exec_fin_date   = ls_conf-conf_end_date.
      ls_timeticket-exec_fin_time   = ls_conf-conf_end_time.
      APPEND ls_timeticket TO lt_timetickets.

      CALL FUNCTION 'BAPI_ALM_CONF_CREATE'
        IMPORTING
          return        = ls_return_c
        TABLES
          timetickets   = lt_timetickets
          detail_return = lt_alm_ret.
      update zpm_act_notes set approvenote = ls_conf-confirmnote wHERE aufnr = ls_conf-maintenanceorder.

      DATA(lv_err_c) = abap_false.
      LOOP AT lt_alm_ret INTO DATA(ls_alm_ret) WHERE type CA 'EA'.
        lv_err_c = abap_true.
        APPEND VALUE #(
          %tky = VALUE #( maintenanceorder = ls_conf-maintenanceorder )
          %msg = new_message(
                          id               = ls_alm_ret-message_id
                          number           = ls_alm_ret-message_number
                          severity         = if_abap_behv_message=>severity-error
                          v1               = ls_alm_ret-message_v1
                          v2               = ls_alm_ret-message_v2
                          v3               = ls_alm_ret-message_v3
                          v4               = ls_alm_ret-message_v4 )
        ) TO reported-zr_pm_order.
      ENDLOOP.

*      IF lv_err_c = abap_false.
*        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*          EXPORTING
*            wait = abap_true.

      DATA(lv_objnr_c) = CONV j_objnr( |OR{ ls_conf-maintenanceorder }| ).
      CALL FUNCTION 'STATUS_CHANGE_EXTERN'
        EXPORTING
          objnr               = lv_objnr_c
          user_status         = 'E0003'
        EXCEPTIONS
          object_not_found    = 1
          status_inconsistent = 2
          status_not_allowed  = 3
          OTHERS              = 4.
*      ELSE.
*        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
*      ENDIF.
      lhc_zr_pm_order=>gs_mail_daata-uname = ls_conf-NotificationCreatedUser.
      lhc_zr_pm_order=>gs_mail_daata-subject = |the Notification { ls_conf-notificationnumber } has Confirmed |.
      lhc_zr_pm_order=>gs_mail_daata-body = |the order { ls_conf-MaintenanceOrder } status has been Confirmed for your Notification { ls_conf-notificationnumber } please Approve the Order |.
      lhc_zr_pm_order=>gs_mail_daata-doctype = 'O'.
      lhc_zr_pm_order=>gs_mail_daata-docnumber = ls_conf-MaintenanceOrder.
      lhc_zr_pm_order=>sending_email( is_mail = lhc_zr_pm_order=>gs_mail_daata ).


    ENDLOOP.
    CLEAR lhc_zr_pm_order=>gt_order_confirm_buffer.


    " ──────────────────────────────────────────────
    " 4) APPROVE: Tarihleri güncelle + Statü → APPROVED
    " ──────────────────────────────────────────────

    IF lhc_zr_pm_order=>gt_order_approve_buffer IS NOT INITIAL.
      SELECT * INTO TABLE @DATA(lt_partners_all)
        FROM zv_pm_order_partner
        FOR ALL ENTRIES IN @lhc_zr_pm_order=>gt_order_approve_buffer
        WHERE MaintenanceOrder = @lhc_zr_pm_order=>gt_order_approve_buffer-maintenanceorder.
    ENDIF.
    LOOP AT lhc_zr_pm_order=>gt_order_approve_buffer INTO DATA(ls_aprv).

      IF ls_aprv-_ar = 'A'.
        DATA: ls_header_update   TYPE bapi2080_nothdri,
              ls_header_update_x TYPE bapi2080_nothdri_x,
              lt_noitemi_x       TYPE TABLE OF bapi2080_notitemi_x,
              lt_return_hdr      TYPE TABLE OF bapiret2.
        CLEAR: ls_header_update, ls_header_update_x, lt_return_hdr.



        ls_header_update-endmlfndate   = ls_aprv-actual_end_date.
        ls_header_update_x-endmlfndate = 'X'.

        ls_header_update-endmlfntime   = ls_aprv-actual_end_time.
        ls_header_update_x-endmlfntime = 'X'.

        CALL FUNCTION 'BAPI_ALM_NOTIF_DATA_MODIFY'
          EXPORTING
            number        = ls_aprv-notificationnumber
            notifheader   = ls_header_update
            notifheader_x = ls_header_update_x
          TABLES
            return        = lt_return_hdr.

        update zpm_act_notes set approvenote = ls_aprv-approvenote wHERE aufnr = ls_aprv-notificationnumber.

        DATA(lv_hdr_error) = abap_false.
        LOOP AT lt_return_hdr TRANSPORTING NO FIELDS WHERE type = 'E' OR type = 'A'.
          lv_hdr_error = abap_true.
          EXIT.
        ENDLOOP.

        IF lv_hdr_error = abap_false.
          CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
            EXPORTING
              number = ls_aprv-notificationnumber
            TABLES
              return = lt_return_hdr.
        ENDIF..
        DATA(lv_err_a) = abap_false.
        LOOP AT lt_return_hdr INTO DATA(ls_return_a) WHERE type CA 'EA'.
          lv_err_a = abap_true.
          APPEND VALUE #(
            %tky = VALUE #( maintenanceorder = ls_aprv-maintenanceorder )
            %msg = new_message(
                            id               = ls_return_a-id
                            number           = ls_return_a-number
                            severity         = if_abap_behv_message=>severity-error
                            v1               = ls_return_a-message_v1
                            v2               = ls_return_a-message_v2
                            v3               = ls_return_a-message_v3
                            v4               = ls_return_a-message_v4 )
          ) TO reported-zr_pm_order.

        ENDLOOP.
        "elseif ls_aprv-_ar = 'Q'.
        "          lt_methods-refnumber  = '000001'.
        "lt_methods-objecttype = 'HEADER'.
        "lt_methods-method     = 'CREATETONOTIF'.

      ENDIF.
      IF lv_err_a = abap_false OR ls_aprv-_ar = 'R'.
        DATA(lv_objnr_a) = CONV j_objnr( |OR{ ls_aprv-maintenanceorder }| ).
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr               = lv_objnr_a
            user_status         = COND #( WHEN ls_aprv-_ar = 'R' THEN 'E0005' ELSE 'E0004' )
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
        update zpm_act_notes set rejectnote = ls_aprv-approvenote wHERE aufnr = ls_aprv-maintenanceorder.

      ENDIF.

      LOOP AT lt_partners_all INTO DATA(ls_partner) WHERE MaintenanceOrder = ls_aprv-maintenanceorder.
        lhc_zr_pm_order=>gs_mail_daata-uname = ls_partner-Partner.
        lhc_zr_pm_order=>gs_mail_daata-subject = |the Notification { ls_aprv-notificationnumber } has { COND #( WHEN ls_aprv-_ar = 'R' THEN 'Rejected' ELSE 'Approved' )  } |.
        lhc_zr_pm_order=>gs_mail_daata-body = |the order { ls_aprv-MaintenanceOrder } status has been { COND #( WHEN ls_aprv-_ar = 'R' THEN 'Rejected' ELSE 'Approved' ) } for your Notification { ls_aprv-notificationnumber } please check the Order |.
        lhc_zr_pm_order=>gs_mail_daata-doctype = 'O'.
        lhc_zr_pm_order=>gs_mail_daata-docnumber = ls_aprv-MaintenanceOrder.
        lhc_zr_pm_order=>sending_email( is_mail = lhc_zr_pm_order=>gs_mail_daata ).
      ENDLOOP.
    ENDLOOP.

    "5. Component modification
    DATA: lt_return_cd    TYPE bapiret2_t,
          ls_return       TYPE bapiret2,
          lt_methods      TYPE STANDARD TABLE OF bapi_alm_order_method,
          ls_methods      LIKE LINE OF lt_methods,
          lt_header       TYPE STANDARD TABLE OF bapi_alm_order_headers_i,
          ls_header       LIKE LINE OF lt_header,
          lt_header_up    TYPE STANDARD TABLE OF bapi_alm_order_headers_up,
          ls_header_up    LIKE LINE OF lt_header_up,
          lt_numbers      TYPE STANDARD TABLE OF bapi_alm_numbers,
          ls_numbers      LIKE LINE OF lt_numbers,
          lt_component    TYPE STANDARD TABLE OF bapi_alm_order_component,
          ls_component    LIKE LINE OF lt_component,
          lt_component_up TYPE STANDARD TABLE OF bapi_alm_order_component_up,
          ls_component_up LIKE LINE OF lt_component_up,
          lt_operation    TYPE STANDARD TABLE OF bapi_alm_order_operation,
          ls_operation    LIKE LINE OF lt_operation,
          lt_operation_up TYPE STANDARD TABLE OF bapi_alm_order_operation_up,
          ls_operation_up LIKE LINE OF lt_operation_up.


    LOOP AT lhc_zr_pm_order=>gt_order_component_buffer INTO DATA(ls_comp_action)
    WHERE updkz = 'D' OR updkz = 'I' OR updkz = 'U'.
      EXIT.
    ENDLOOP.
    IF sy-subrc IS INITIAL.

      CLEAR: lt_methods, ls_methods, lt_component, ls_component, lt_component_up, ls_component_up,
             lt_return_cd, lt_numbers.
      DATA(lv_refnum_c) = 0.

      READ TABLE lhc_zr_pm_order=>gt_order_component_buffer INTO DATA(ls_comp_h) INDEX 1.

      " CREATE/CHANGE — one method row per component (same pattern as operations)
      DATA(lv_has_comp_create) = abap_false.
      DATA(lv_has_comp_change) = abap_false.

      LOOP AT lhc_zr_pm_order=>gt_order_component_buffer INTO ls_comp_action
      WHERE updkz = 'I' OR updkz = 'U'.
        CLEAR: ls_component, ls_component_up.

        SELECT MIN( c~vornr ) INTO ls_comp_action-MaintenanceOrderOperation
          FROM afvc AS c INNER JOIN caufv AS o ON o~aufpl EQ c~aufpl
          WHERE o~aufnr EQ ls_comp_h-MaintenanceOrder
            AND c~phflg EQ space.
        SELECT SINGLE rsnum INTO ls_component-reserv_no
          FROM afvc AS c INNER JOIN caufv AS o ON o~aufpl EQ c~aufpl
          WHERE o~aufnr EQ ls_comp_h-MaintenanceOrder
            AND c~vornr  EQ ls_comp_action-MaintenanceOrderOperation
            AND c~phflg  EQ space.

        ls_component-res_item                    = ls_comp_action-ReservationItem.
        ls_component-activity                    = ls_comp_action-MaintenanceOrderOperation.
        ls_component-item_number                 = ls_comp_action-ReservationItem.
        ls_component-material                    = ls_comp_action-Material.
        ls_component-requirement_quantity        = ls_comp_action-RequirementQuantityInBaseUnit.
        ls_component-requirement_quantity_unit   = ls_comp_action-BaseUnit.
        ls_component-plant                       = ls_comp_action-Plant.
        ls_component-item_cat                    = 'L'.
        ls_component-stge_loc                    = ls_comp_action-StorageLocation.
        ls_component-backflush                   = 'X'.
        APPEND ls_component TO lt_component.

        ls_component_up-activity                    = COND #( WHEN ls_comp_action-updkz EQ 'I' THEN abap_true ELSE abap_false ).
        ls_component_up-item_number                 = abap_true.
        ls_component_up-material                    = abap_true.
        ls_component_up-requirement_quantity        = abap_true.
        ls_component_up-requirement_quantity_unit   = abap_true.
        ls_component_up-plant                       = abap_true.
        ls_component_up-item_cat                    = abap_true.
        ls_component_up-stge_loc                    = abap_true.
        ls_component_up-backflush                   = abap_true.
        APPEND ls_component_up TO lt_component_up.

        lv_refnum_c += 1.
        IF ls_comp_action-updkz = 'I'.
          APPEND VALUE #( refnumber = lv_refnum_c objecttype = 'COMPONENT'
                          method = 'CREATE'
                          objectkey = |{ ls_comp_h-MaintenanceOrder }{ ls_comp_action-ReservationItem }| ) TO lt_methods.
          lv_has_comp_create = abap_true.
        ELSE.
          APPEND VALUE #( refnumber = lv_refnum_c objecttype = 'COMPONENT'
                          method = 'CHANGE'
                          objectkey = |{ ls_comp_h-MaintenanceOrder }{ ls_comp_action-ReservationItem }| ) TO lt_methods.
          lv_has_comp_change = abap_true.
        ENDIF.

      ENDLOOP.

      " DELETE — read existing component data once, then one method row per component
      DATA: lt_components TYPE STANDARD TABLE OF bapi_alm_order_component_e.

      CALL FUNCTION 'BAPI_ALM_ORDER_GET_DETAIL'
        EXPORTING
          number        = ls_comp_h-MaintenanceOrder
        TABLES
          et_components = lt_components
          return        = lt_return_cd.

      DATA(lv_has_comp_delete) = abap_false.
      LOOP AT lhc_zr_pm_order=>gt_order_component_buffer INTO ls_comp_action
      WHERE updkz = 'D'.
        CLEAR: ls_component, ls_component_up.
        READ TABLE lt_components INTO DATA(ls_components) WITH KEY res_item = ls_comp_action-ReservationItem.
        MOVE-CORRESPONDING ls_components TO ls_component.
        ls_component-item_number = ls_comp_action-ReservationItem.
        APPEND ls_component TO lt_component.

        ls_component_up-activity    = abap_true.
        ls_component_up-item_number = abap_true.
        APPEND ls_component_up TO lt_component_up.

        lv_refnum_c += 1.
        APPEND VALUE #( refnumber = lv_refnum_c objecttype = 'COMPONENT'
                        method = 'DELETE'
                        objectkey = |{ ls_comp_h-MaintenanceOrder }{ ls_comp_action-ReservationItem }| ) TO lt_methods.
        lv_has_comp_delete = abap_true.

      ENDLOOP.

      " SAVE must have the highest refnumber
      lv_refnum_c += 1.
      APPEND VALUE #( refnumber = lv_refnum_c objecttype = ''
                      method = 'SAVE' objectkey = ls_comp_h-MaintenanceOrder ) TO lt_methods.

      CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
        TABLES
          it_methods      = lt_methods
          it_component    = lt_component
          it_component_up = lt_component_up
          return          = lt_return_cd
          et_numbers      = lt_numbers.

      LOOP AT lt_return_cd INTO ls_return_a WHERE type CA 'EA'.
        APPEND VALUE #(
          %tky = VALUE #( maintenanceorder = ls_comp_h-maintenanceorder )
          %msg = new_message(
                          id               = ls_return_a-id
                          number           = ls_return_a-number
                          severity         = if_abap_behv_message=>severity-error
                          v1               = ls_return_a-message_v1
                          v2               = ls_return_a-message_v2
                          v3               = ls_return_a-message_v3
                          v4               = ls_return_a-message_v4 )
        ) TO reported-component.
      ENDLOOP.
    ENDIF.

    LOOP AT lhc_zr_pm_order=>gt_order_operation_buffer INTO DATA(ls_operation_action)
    WHERE updkz = 'D' OR updkz = 'I' OR updkz = 'U'.
      EXIT.
    ENDLOOP.
    IF sy-subrc IS INITIAL.

      CLEAR: lt_methods, ls_methods, lt_operation, ls_operation, lt_operation_up, ls_operation_up,
             lt_return_cd, lt_numbers.
      DATA(lv_refnum_o) = 0.

      READ TABLE lhc_zr_pm_order=>gt_order_operation_buffer INTO DATA(ls_operation_action_h) INDEX 1.

      DATA(lv_has_create) = abap_false.
      DATA(lv_has_change) = abap_false.
      DATA(lv_has_delete) = abap_false.

      " Read existing operations once — needed for control_key on CHANGE and full data on DELETE
      DATA: lt_operations1 TYPE STANDARD TABLE OF bapi_alm_order_operation_e.
      CALL FUNCTION 'BAPI_ALM_ORDER_GET_DETAIL'
        EXPORTING
          number        = ls_operation_action_h-MaintenanceOrder
        TABLES
          et_operations = lt_operations1
          return        = lt_return_cd.
      CLEAR lt_return_cd.

      " Collect new operations (CREATE) — one method entry per operation, objectkey = order+activity
      LOOP AT lhc_zr_pm_order=>gt_order_operation_buffer INTO DATA(ls_opt_action)
        WHERE updkz = 'I'.
        CLEAR: ls_operation, ls_operation_up.
        ls_operation-activity    = ls_opt_action-MaintenanceOrderOperation.
        ls_operation-description = ls_opt_action-OperationDescription.
        ls_operation-plant       = ls_opt_action-Plant.
        ls_operation-work_cntr   = ls_opt_action-WorkCenter.
        ls_operation-control_key = 'PM01'.
        APPEND ls_operation TO lt_operation.
        ls_operation_up-activity    = abap_true.
        ls_operation_up-description = abap_true.
        ls_operation_up-plant       = abap_true.
        ls_operation_up-work_cntr   = abap_true.
        ls_operation_up-control_key = abap_true.
        APPEND ls_operation_up TO lt_operation_up.
        lv_refnum_o += 1.
        APPEND VALUE #( refnumber  = lv_refnum_o objecttype = 'OPERATION'
                        method     = 'CREATE'
                        objectkey  = |{ ls_operation_action_h-MaintenanceOrder }{ ls_opt_action-MaintenanceOrderOperation }| ) TO lt_methods.
        lv_has_create = abap_true.
      ENDLOOP.

      " Collect changed operations (CHANGE) — start from current DB values, overlay buffer fields
      LOOP AT lhc_zr_pm_order=>gt_order_operation_buffer INTO ls_opt_action
        WHERE updkz = 'U'.
        CLEAR: ls_operation, ls_operation_up.
        READ TABLE lt_operations1 INTO DATA(ls_existing_op)
          WITH KEY activity = ls_opt_action-MaintenanceOrderOperation.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        MOVE-CORRESPONDING ls_existing_op TO ls_operation.
        ls_operation-activity = ls_opt_action-MaintenanceOrderOperation.
        IF ls_opt_action-OperationDescription IS NOT INITIAL.
          ls_operation-description = ls_opt_action-OperationDescription.
        ENDIF.
        IF ls_opt_action-Plant IS NOT INITIAL.
          ls_operation-plant = ls_opt_action-Plant.
        ENDIF.
        IF ls_opt_action-WorkCenter IS NOT INITIAL.
          ls_operation-work_cntr = ls_opt_action-WorkCenter.
        ENDIF.
        APPEND ls_operation TO lt_operation.
        lv_refnum_o += 1.
        APPEND VALUE #( refnumber  = lv_refnum_o objecttype = 'OPERATION'
                        method     = 'CHANGE'
                        objectkey  = |{ ls_operation_action_h-MaintenanceOrder }{ ls_opt_action-MaintenanceOrderOperation }| ) TO lt_methods.
        lv_has_change = abap_true.
      ENDLOOP.

      " Collect deleted operations — one method entry per operation, objectkey = order+activity
      LOOP AT lhc_zr_pm_order=>gt_order_operation_buffer INTO DATA(ls_opt_del)
        WHERE updkz = 'D'.
        CLEAR ls_operation.
        ls_operation-activity = ls_opt_del-MaintenanceOrderOperation.
        APPEND ls_operation TO lt_operation.
        lv_refnum_o += 1.
        APPEND VALUE #( refnumber = lv_refnum_o objecttype = 'OPERATION'
                        method    = 'DELETE'
                        objectkey = |{ ls_opt_del-MaintenanceOrder }{ ls_opt_del-MaintenanceOrderOperation }| ) TO lt_methods.
        lv_has_delete = abap_true.
      ENDLOOP.

      IF lv_has_create = abap_true OR lv_has_change = abap_true OR lv_has_delete = abap_true.
        lv_refnum_o += 1.
        APPEND VALUE #( refnumber = lv_refnum_o objecttype = ''
                        method = 'SAVE' objectkey = ls_operation_action_h-MaintenanceOrder ) TO lt_methods.

        CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
          TABLES
            it_methods      = lt_methods
            it_operation    = lt_operation
            it_operation_up = lt_operation_up
            return          = lt_return_cd
            et_numbers      = lt_numbers.

        LOOP AT lt_return_cd INTO ls_return_a WHERE type CA 'EA'.
          APPEND VALUE #(
            %tky = VALUE #( maintenanceorder = ls_operation_action_h-maintenanceorder )
            %msg = new_message(
                            id               = ls_return_a-id
                            number           = ls_return_a-number
                            severity         = if_abap_behv_message=>severity-error
                            v1               = ls_return_a-message_v1
                            v2               = ls_return_a-message_v2
                            v3               = ls_return_a-message_v3
                            v4               = ls_return_a-message_v4 )
          ) TO reported-zr_pm_order_operation.
        ENDLOOP.
      ENDIF.
    ENDIF.


    " ──────────────────────────────────────────────
    " 6) PARTNER modification (function 'VU')
    "    Single BAPI call: DELETE rows first (lower refnum), CREATE rows second,
    "    SAVE always last. Same pattern as component/operation sections above.
    " ──────────────────────────────────────────────
    DATA: lt_methods_p    TYPE STANDARD TABLE OF bapi_alm_order_method,
          lt_partner_p    TYPE STANDARD TABLE OF bapi_alm_order_partn_mul,
          lt_partner_up_p TYPE STANDARD TABLE OF bapi_alm_order_partn_mul_up,
          lt_return_p     TYPE bapiret2_t,
          lt_numbers_p    TYPE STANDARD TABLE OF bapi_alm_numbers,
          lt_bapi_partners TYPE STANDARD TABLE OF ihpa,
          lv_refnum_p      TYPE i.

    LOOP AT lhc_zr_pm_order=>gt_order_partner_buffer TRANSPORTING NO FIELDS
      WHERE updkz = 'I' OR updkz = 'D'.
      EXIT.
    ENDLOOP.

    IF sy-subrc IS INITIAL.

      READ TABLE lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_part_h) INDEX 1.

      SELECT * FROM ihpa
        WHERE objnr    = @( CONV j_objnr( |OR{ ls_part_h-MaintenanceOrder ALPHA = IN }| ) )
          AND kzloesch IS INITIAL
        INTO TABLE @lt_bapi_partners.

      CLEAR: lt_methods_p, lt_partner_p, lt_partner_up_p, lt_return_p, lt_numbers_p.
      lv_refnum_p = 0.
      DATA(lv_has_delete_p) = abap_false.
      DATA(lv_has_create_p) = abap_false.

      " ── Collect DELETEs — all partners in one DELETE method row ──
      LOOP AT lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_part_del)
        WHERE updkz = 'D'.
        APPEND VALUE #( orderid        = ls_part_del-MaintenanceOrder
                        partn_role     = ''
                        partner        = ''
                        partn_role_old = ls_part_del-PartnerFunction
                        partner_old    = |{ ls_part_del-Partner ALPHA = IN }| ) TO lt_partner_p.
        APPEND VALUE #( orderid        = ls_part_del-MaintenanceOrder
                        partn_role     = 'X'
                        partner        = 'X'
                        partn_role_old = ls_part_del-PartnerFunction
                        partner_old    = |{ ls_part_del-Partner ALPHA = IN }| ) TO lt_partner_up_p.
        lv_has_delete_p = abap_true.
      ENDLOOP.

      IF lv_has_delete_p = abap_true.
        lv_refnum_p += 1.
        APPEND VALUE #( refnumber  = lv_refnum_p  objecttype = 'PARTNER'  method = 'DELETE'
                        objectkey  = ls_part_h-MaintenanceOrder ) TO lt_methods_p.
      ENDIF.

      " ── Collect CREATEs — all partners in one CREATE method row ──
      LOOP AT lhc_zr_pm_order=>gt_order_partner_buffer INTO DATA(ls_part_action)
        WHERE updkz = 'I'.
        IF line_exists( lt_bapi_partners[ counter = ls_part_action-PartnerCounter ] ).
          CONTINUE.
        ENDIF.
        DATA(lv_partner_alpha) = |{ ls_part_action-Partner ALPHA = IN }|.
        APPEND VALUE #( orderid    = ls_part_action-MaintenanceOrder
                        partn_role = ls_part_action-PartnerFunction
                        partner    = lv_partner_alpha ) TO lt_partner_p.
        APPEND VALUE #( orderid    = ls_part_action-MaintenanceOrder
                        partn_role = 'X'  partner = 'X' ) TO lt_partner_up_p.
        lv_has_create_p = abap_true.
      ENDLOOP.

      IF lv_has_create_p = abap_true.
        lv_refnum_p += 1.
        APPEND VALUE #( refnumber  = lv_refnum_p  objecttype = 'PARTNER'  method = 'CREATE'
                        objectkey  = ls_part_h-MaintenanceOrder ) TO lt_methods_p.
      ENDIF.

      " ── SAVE must have the highest refnumber ──
      IF lv_has_delete_p = abap_true OR lv_has_create_p = abap_true.
        lv_refnum_p += 1.
        APPEND VALUE #( refnumber  = lv_refnum_p  objecttype = ''  method = 'SAVE'
                        objectkey  = ls_part_h-MaintenanceOrder ) TO lt_methods_p.

        CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
          TABLES
            it_methods    = lt_methods_p
            it_partner    = lt_partner_p
            it_partner_up = lt_partner_up_p
            return        = lt_return_p
            et_numbers    = lt_numbers_p.

        LOOP AT lt_return_p INTO DATA(ls_return_p) WHERE type CA 'EA'.
          APPEND VALUE #( %tky = VALUE #( maintenanceorder = ls_part_h-maintenanceorder )
            %msg = new_message( id = ls_return_p-id  number = ls_return_p-number
                                severity = if_abap_behv_message=>severity-error
                                v1 = ls_return_p-message_v1  v2 = ls_return_p-message_v2
                                v3 = ls_return_p-message_v3  v4 = ls_return_p-message_v4 ) )
          TO reported-zr_pm_order_partner.
        ENDLOOP.
      ENDIF.

    ENDIF.

    CLEAR lhc_zr_pm_order=>gt_order_approve_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_component_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_operation_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_partner_buffer.
    CLEAR lhc_zr_pm_order=>gt_op_counters.
    CLEAR lhc_zr_pm_order=>gt_part_counters.
  ENDMETHOD.

  METHOD cleanup.
    " BUFFER TEMİZLİĞİ: Hata durumunda (Rollback) tamponun sıfırlanması şarttır.
    CLEAR lhc_zr_pm_order=>gt_order_start_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_confirm_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_approve_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_update_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_operation_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_component_buffer.
    CLEAR lhc_zr_pm_order=>gt_order_partner_buffer.
    CLEAR lhc_zr_pm_order=>gt_op_counters.
    CLEAR lhc_zr_pm_order=>gt_part_counters.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.