@EndUserText.label: 'Maintenance Order - Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@UI.headerInfo: {
    typeName:        'Maintenance Order',
    typeNamePlural:  'Maintenance Orders',
    title.value:     'MaintenanceOrder',
    description.value: 'MaintenanceOrderDesc'    
}
define root view entity ZC_PM_ORDER   provider contract transactional_query
  as projection on ZR_PM_ORDER

{ 
      @UI.facet: [
        // ── Object Page: üst bilgi header facet (fieldgroup)
        { id:              'HeaderFacet',
          purpose:         #HEADER,
          type:            #FIELDGROUP_REFERENCE,
          targetQualifier: 'HeaderGroup',
          label:           'Order Info' },

        // ── Object Page: içerik koleksiyonu
        { id:              'GeneralSection',
          purpose:         #STANDARD,
          type:            #COLLECTION,
          label:           'General',
          position:        10 },

        // ── Dates, Times, Plant, WorkCenter fieldgroup
        { id:              'DatesPlantFacet',
          purpose:         #STANDARD,
          type:            #FIELDGROUP_REFERENCE,
          targetQualifier: 'DatesPlantGroup',
          label:           'Dates, Plant & Work Center',
          parentId:        'GeneralSection',
          position:        10 },

        // ── Components tab (SAP standard I_MaintenanceOrderComponent_2)
        { id:              'ComponentsFacet',
          purpose:         #STANDARD,
          type:            #LINEITEM_REFERENCE,
          label:           'Components',
          position:        20,
          targetElement:   '_Component' },

        // ── Operations tab (SAP standard I_MaintenanceOrderOperation)
        { id:              'OperationsFacet',
          purpose:         #STANDARD,
          type:            #LINEITEM_REFERENCE,
          label:           'Operations',
          position:        30,
          targetElement:   '_Operation' },
          
        { id:              'PartnerFacet',
          purpose:         #STANDARD,
          type:            #LINEITEM_REFERENCE,
          label:           'Partner',
          position:        30,
          targetElement:   '_Partner' },
          
        { id:              'StatusFacet',
          purpose:         #STANDARD,
          type:            #PRESENTATIONVARIANT_REFERENCE,
          label:           'Status',
          position:        40,
          targetElement:   '_Status',
          targetQualifier: 'SortByDate'
           }
      ] 

  key MaintenanceOrder,
      MaintenanceOrderDesc,
      MaintPriority,
      MaintPriorityType,
      MaintenanceNotification,
      stat,
      CreationDate,
      CreationTime,
      CreatedByUser,
      LastChangeByUser,
      LastChangeDateTime,
      Equipment,
      Assembly,
      SerialNumber,
      Material,
      MaintenancePlanningPlant,
      MaintenancePlant,
      MaintenancePlannerGroup,
      MaintOrderType, 
      MaintenanceOrderCategory,
      CompanyCode,
      ControllingArea,
      ResponsibleCostCenter,
      BusinessArea,
      FunctionalArea,
      ProfitCenter,
      Currency,
      WorkCenterInternalID,
      WorkCenterTypeCode,
      MainWorkCenter,
      MainWorkCenterPlant,
      MaintOrdBasicStartDate,
      MaintOrdBasicStartTime,
      MaintOrdBasicEndDate,
      MaintOrdBasicEndTime,
      ScheduledBasicStartDate,
      ScheduledBasicStartTime,
      ScheduledBasicEndDate,
      ScheduledBasicEndTime,
      TechnicalCompletionDate,
      LatestAcceptableCompletionDate,
      MaintOrderReferenceDate,
      MaintOrderReferenceTime,
      MainWorkCompletedDateTime,
      MaintenanceProcessingPhase,
      MaintenanceOrderPlanningCode,
      MaintOrdProcessPhaseCode,
      MaintOrdProcessSubPhaseCode,
      MaintenanceOrderInternalID,
      OrderHasLongText,
      MaintenancePlan,
      MaintenanceItem,
      MaintenanceRevision,
      MaintenanceCall,
      LeadingOrder,
      MaintOrderRoutingNumber,
      OperationSystemCondition,
      MaintenanceActivityType,
      MaintObjectLocAcctAssgmtNmbr,
      WBSElementInternalID,
      PersonnelNumber,

      // Associations
      _MaintenanceNotification,
      _Equipment,
      _MaintenancePlanningPlant,
      _LocationPlant,
      _MainWorkCenter,
      _MaintenancePriority,
      _MaintenancePriorityType,
      _MaintenanceOrderType,
      _MaintenanceOrderPhase,
      _StatusObject,
      _StatusObjectActiveStatus,
      _CreatedByUser,
      getri,
      geuzi, 
      //notes
      Confirmnote,
      Rejectnote,
      Approvenote,
      
      // SAP standard sub-entity'ler — ZC projection'larına yönlendir
      _Operation  : redirected to composition child ZC_PM_ORDER_OPERATION,
      _Component  : redirected to composition child ZC_PM_ORDER_COMP,
      _Partner  : redirected to composition child ZC_PM_ORDER_PARTNER,   
      _Status  : redirected to composition child ZC_PM_ORDER_STATUS,
      _MaintenanceOrderCost,
      _MaintenancePlannerGroup,
      _EAMProcessPhase,
      _EAMProcessSubPhase,
      BStatus1,
      BStatus2,
      BStatus3,
      BStatus4,
      task_duration,
      break_down_duration
}
where
       MaintOrderType       = 'BM'
and (   MaintenanceProcessingPhase = '0'
       or MaintenanceProcessingPhase = '1'
       or MaintenanceProcessingPhase = '2' )
