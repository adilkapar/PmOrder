@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Maintenance Order - Base View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
    serviceQuality: #X,
    sizeCategory: #XL,
    dataClass: #TRANSACTIONAL
}

define root view entity ZR_PM_ORDER
  as select from    I_MaintenanceOrder as _order
    left outer join ZV_PM_ORDER_STATUS as j on j.MaintenanceOrder = _order.MaintenanceOrder
    left outer join afko                    on afko.aufnr = _order.MaintenanceOrder
  association [0..*] to ZV_PM_ORDER_PARTNER_CUSER as _vpartner on $projection.MaintenanceOrder = _vpartner.MaintenanceOrder
  composition [0..*] of ZR_PM_ORDER_OPERATION     as _Operation
  composition [0..*] of ZR_PM_ORDER_COMP          as _Component
  composition [0..*] of ZR_PM_ORDER_PARTNER       as _Partner
  composition [0..*] of ZR_PM_ORDER_STATUS        as _Status

{
  key _order.MaintenanceOrder,
      _order.MaintenanceOrderDesc,
      _vpartner.currentuser,
      // Priority
      _order.MaintPriority,
      _order.MaintPriorityType,
      _order._MaintenanceNotification.CreationDate  as NotifCreationDate,
      _order._MaintenanceNotification.CreationTime  as NotifCreationTime,
      // Notification link
      _order.MaintenanceNotification,
      j.stat,
      // Admin
      _order.CreationDate,
      _order.CreationTime,
      _order.CreatedByUser,
      _order.LastChangeByUser,
      _order.LastChangeDateTime,

      // Technical Object
      _order.Equipment,
      _order.Assembly,
      _order.SerialNumber,
      _order.Material,

      // Plant / Organization
      _order.MaintenancePlanningPlant,
      _order.MaintenancePlant,
      _order.MaintenancePlannerGroup,
      @EndUserText.label: 'Maintenance Order Type'
      _order.MaintenanceOrderType                   as MaintOrderType,
      _order.MaintenanceOrderCategory,
      _order.CompanyCode,
      _order.ControllingArea,
      _order.ResponsibleCostCenter,
      _order.BusinessArea,
      _order.FunctionalArea,
      _order.ProfitCenter,
      _order.Currency,

      // Work Center
      _order.WorkCenterInternalID,
      _order.WorkCenterTypeCode,
      _order.MainWorkCenter,
      _order.MainWorkCenterPlant,

      // Dates & Times
      _order.MaintOrdBasicStartDate,
      _order.MaintOrdBasicStartTime,
      _order.MaintOrdBasicEndDate,
      _order.MaintOrdBasicEndTime,
      _order.ScheduledBasicStartDate,
      _order.ScheduledBasicStartTime,
      _order.ScheduledBasicEndDate,
      _order.ScheduledBasicEndTime,
      _order.TechnicalCompletionDate,
      _order.LatestAcceptableCompletionDate,
      _order.MaintOrderReferenceDate,
      _order.MaintOrderReferenceTime,
      _order.MainWorkCompletedDateTime,

      // Status & Phase
      _order.MaintenanceProcessingPhase,
      _order.MaintenanceOrderPlanningCode,
      _order.MaintOrdProcessPhaseCode,
      _order.MaintOrdProcessSubPhaseCode,
      _order.MaintenanceOrderInternalID,
      _order.OrderHasLongText,

      // Maintenance Plan
      _order.MaintenancePlan,
      _order.MaintenanceItem,
      _order.MaintenanceRevision,
      _order.MaintenanceCall,
      _order.LeadingOrder,
      _order.MaintOrderRoutingNumber,

      // Misc
      _order.OperationSystemCondition,
      _order.MaintenanceActivityType,
      _order.MaintObjectLocAcctAssgmtNmbr,
      _order.WBSElementInternalID,
      _order.PersonnelNumber,

      // Associations (I_MaintenanceOrder'dan gelenler, sadece kullanacaklarımız)
      _order._MaintenanceNotification,
      _order._Equipment,
      _order._MaintenancePlanningPlant,
      _order._LocationPlant,
      _order._MainWorkCenter,
      _order._MaintenancePriority,
      _order._MaintenancePriorityType,
      _order._MaintenanceOrderType,
      _order._MaintenanceOrderPhase,
      _order._StatusObject,
      _order._StatusObjectActiveStatus,
      _order._CreatedByUser,
      _order._MaintenanceOrderOperation, // → I_MaintenanceOrderOperation
      _order._MaintenanceOrderComponent, // → I_MaintenanceOrderComponent_2
      _order._MaintenanceOrderCost,
      _order._MaintenancePlannerGroup,
      _order._EAMProcessPhase,
      _order._EAMProcessSubPhase,
      _Operation,
      _Component,
      _Partner,
      _Status,
      //calcuılated fields
      j.BStatus1,
      j.BStatus2,
      j.BStatus3,
      j.BStatus4,
      _order._MaintenanceNotification.CreatedByUser as NotificationCreatedUser,
      case
      /* Eğer başlangıç tarihi hiç girilmemişse veya boşluksa süreyi 0 kabul et */
          when _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionStartDate is null
            or _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionStartDate = '00000000'
          then cast( 0 as abap.dec( 10, 2 ) )

          else
            cast( cast(
              tstmp_seconds_between(

      /* BAŞLANGIÇ ZAMAN DAMGASI (240000 Kontrollü) */
                dats_tims_to_tstmp(
                  _order._MaintenanceNotification._PMNotifMaintenanceData._MaintenanceNotification.CreationDate,
                  case
                    when _order._MaintenanceNotification._PMNotifMaintenanceData._MaintenanceNotification.CreationTime = '240000'
                    then '235959'
                    else _order._MaintenanceNotification._PMNotifMaintenanceData._MaintenanceNotification.CreationTime
                  end,
                  abap_system_timezone( $session.client, 'NULL' ),
                  $session.client,
                  'NULL'
                ),

      /* BİTİŞ ZAMAN DAMGASI (Koşullu ve 240000 Kontrollü) */
                case
                  when _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionEndDate is null
                    or _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionEndDate = '00000000'
                  then tstmp_current_utctimestamp()

                  else dats_tims_to_tstmp(
                         _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionEndDate,
                         case
                           when _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionEndTime = '240000'
                           then '235959'
                           else _order._MaintenanceNotification._PMNotifMaintenanceData.MalfunctionEndTime
                         end,
                         abap_system_timezone( $session.client, 'NULL' ),
                         $session.client,
                         'NULL'
                       )
                end,

                'NULL'

              ) as abap.fltp
            ) / 3600.0 as abap.dec( 10, 2 ) )

        end                                         as break_down_duration,


      /* ==================================================================== */
      /* 2. ALAN: task_duration                                               */
      /* ==================================================================== */
      case
      /* Eger baslangic tarihi hic girilmemisse veya bosluksa sureyi 0 kabul et */
        when _order.MaintOrdBasicStartDate is null
          or _order.MaintOrdBasicStartDate = '00000000'
        then cast( 0 as abap.dec( 10, 2 ) )

        else
          cast( cast(
            tstmp_seconds_between(

      /* BASLANGIC ZAMAN DAMGASI (240000 Kontrollü) */
              dats_tims_to_tstmp(
                _order.MaintOrdBasicStartDate,
                case when _order.MaintOrdBasicStartTime = '240000' then '235959' else _order.MaintOrdBasicStartTime end,
                abap_system_timezone( $session.client, 'NULL' ),
                $session.client,
                'NULL'
              ),

      /* BITIS ZAMAN DAMGASI (Kosullu ve 240000 Kontrollü) */
              case
                when afko.getri is null
                  or afko.getri = '00000000'
                then tstmp_current_utctimestamp()

                else dats_tims_to_tstmp(
                       afko.getri,
                       case when afko.geuzi = '240000' then '235959' else afko.geuzi end,
                       abap_system_timezone( $session.client, 'NULL' ),
                       $session.client,
                       'NULL'
                     )
              end,

              'NULL'

            ) as abap.fltp
          ) / 3600.0 as abap.dec( 10, 2 ) )

      end                                           as task_duration


}

where
       _order.MaintenanceOrderType       = 'BM'
  and(
       _order.MaintenanceProcessingPhase = '0'
    or _order.MaintenanceProcessingPhase = '1'
    or _order.MaintenanceProcessingPhase = '2'
  )