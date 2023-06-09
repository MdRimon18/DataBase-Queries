USE [GarmentsERP]
GO
/****** Object:  UserDefinedFunction [dbo].[BudgetCostPercentageCalculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE FUNCTION [dbo].[BudgetCostPercentageCalculation] 
(	
		@budgetCost float,
		@precostinId int
)
RETURNS DECIMAL(18,2)
AS
BEGIN
DECLARE @qPercentage DECIMAL(18,2)=0
DECLARE @Fob float=0
DECLARE @AvgPrice float=0
DECLARE @JobQty float=0
DECLARE @SingleFob float=0  
 select @JobQty=ord.JobQuantity,@AvgPrice=ord.AvgUnitPrice from PreCostings pc 
 left join TblInitialOrders ord on ord.OrderAutoID=pc.OrderId where pc.PrecostingId=@precostinId
  set @Fob=@AvgPrice*@JobQty;
  set @SingleFob=((@budgetCost/12)*@JobQty);
  set @qPercentage=((@SingleFob/@Fob)*100);

 RETURN @qPercentage
END
GO
/****** Object:  UserDefinedFunction [dbo].[CheckCnsmptnIdExistOrNotForFabBkng]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE FUNCTION [dbo].[CheckCnsmptnIdExistOrNotForFabBkng] (			@ConsmptionId int 		 )RETURNS intASBEGIN  RETURN (select (CASE WHEN count(Id)>0  THEN 1 ELSE 0 END)from PartialFabricBookingItemDtlsChildswhere fabCnsId=@ConsmptionId)  END
GO
/****** Object:  UserDefinedFunction [dbo].[CheckFabricCstIdExistOrNotForFabBkng]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE FUNCTION [dbo].[CheckFabricCstIdExistOrNotForFabBkng] (			@fabricId int,		@color varchar(max))RETURNS intASBEGIN  RETURN (select (CASE WHEN count(Id)>0  THEN 1 ELSE 0 END)from PartialFabricBookingItemDtlsChildswhere FabricCostId=@fabricId and UPPER(dbo.TRIM(GmtsColor))=UPPER(dbo.TRIM(@color)))END
GO
/****** Object:  UserDefinedFunction [dbo].[CheckIsConsumptionIdForEmblBkngExist]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[CheckIsConsumptionIdForEmblBkngExist] 
(	
		@ConsumptinId int
)
RETURNS int
AS
BEGIN

 RETURN (select (CASE WHEN count(Id)>0  THEN 1 ELSE 0 END)
from EmbellishmentWODetailsChilds
where EmbelCnsmtnId=@ConsumptinId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ColorAndSizeWiseBreakDownTableLeangthRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  create  FUNCTION [dbo].[ColorAndSizeWiseBreakDownTableLeangthRpt]( @InitialOrderId int )RETURNS  intASBEGINDeclare @tblLenght intSelect @tblLenght=Count(*)  From    (Select OrderAutoID,PO_Quantity,szeWiseBrkdwn.Rate as sizeQnty from   TblInitialOrders as ord  left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID  left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID  where  ord.OrderAutoID=@InitialOrderId and   size is not null and Color is not null 	 group by  	 OrderAutoID, 	  PO_Quantity,szeWiseBrkdwn.Rate) as tble  RETURN @tblLenghtEND;
GO
/****** Object:  UserDefinedFunction [dbo].[ColorWiseQuantityByOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   create  FUNCTION [dbo].[ColorWiseQuantityByOrderId](@OrderId int )    RETURNS   @ATTTble TABLE(	[OrderId] [int] NULL,	[Color] varchar(100),	[Quantity] [float] 	)ASBEGIN      INSERT INTO @ATTTble select OrderId=@OrderId,Color,sum(Quanity) as Quantity From  SizePannelPodetails where PoId in(   select PoDetID From TblPodetailsInfroes where InitialOrderID=@OrderId)   group by Color    RETURN ;END;
GO
/****** Object:  UserDefinedFunction [dbo].[CommissionCostPivotTblV2]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from CommissionCostPivotTblV2()CREATE FUNCTION [dbo].[CommissionCostPivotTblV2]( 	 )    RETURNS   @ATTTble  TABLE(	[PrecostingId] [int]  NOT NULL	 	 ,[Foreigns] float null,	 [Locals] float null)ASBEGINdeclare @tesTbl TABLE(	[PrecostingId] [int]  NOT NULL	 	 ,[Foreigns] float null,	 [Locals] float null)DECLARE           @PrecostingId int,         @Particulars nvarchar(max),		 @Foreign float,	    @Local float,		@TotalAmount float   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR  select   prcStng.PrecostingId,  cmsCost.Particulars,	sum(cmsCost.Amount/12*dbo.GetPoQuantityByOrderId(prcStng.OrderId)) as TotalAmount from CommissionCosts  as cmsCostleft join PreCostings as prcStng on prcStng.PrecostingId=cmsCost.PrecostingIdwhere  prcStng.PrecostingId is not null  group by   prcStng.PrecostingId,  cmsCost.Particulars  OPEN CUR_TESTFETCH NEXT FROM CUR_TEST INTO @PrecostingId ,         @Particulars ,   	    @TotalAmount WHILE @@FETCH_STATUS = 0BEGIN     set  @PrecostingId=@PrecostingId  if @Particulars='Foreign' begin    	set @Foreign= @TotalAmount  end   if @Particulars='Local' begin    	set @Local= @TotalAmount  end   FETCH NEXT FROM CUR_TEST INTO @PrecostingId ,         @Particulars,   	    @TotalAmount Insert into @tesTbl VALUES (@PrecostingId ,	    @Foreign,		@Local);		set @Foreign=null;		set @local=null;ENDCLOSE CUR_TESTDEALLOCATE CUR_TESTinsert into @ATTTble   SELECT PrecostingId, sum(Foreigns), sum(Locals) FROM @tesTbl GROUP BY PrecostingId       RETURN ;END;  
GO
/****** Object:  UserDefinedFunction [dbo].[CommrclCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 --select * from CommrclCostPivotTbl()
CREATE  FUNCTION [dbo].[CommrclCostPivotTbl](
 
	 


)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL	 
	 ,[LCCost]float null,
	 [PortClearing]float null,
	 [Transportation]float null,
	 [AllTogether]float null)
AS
BEGIN
insert into @ATTTble  select PrecostingId,[AllTogether],[LCCost],[PortClearing],[Transportation]
from
 (select 
 prcStng.PrecostingId,
   CmrclCst.Item ,
   CmrclCst.RateIn,
	sum(CmrclCst.RateIn*(dbo.GetPoQuantityByOrderId(prcStng.OrderId)/12)) as tAmount 
     
 from CommercialCosts  as CmrclCst
left join PreCostings as prcStng on prcStng.PrecostingId=CmrclCst.PrecostingId 
where prcStng.PrecostingId is not null   group by prcStng.PrecostingId,  
   CmrclCst.Item,
   CmrclCst.RateIn) as sourcTbl
   PIVOT(
   Max(tAmount) for   Item in ([AllTogether],[LCCost],[PortClearing],[Transportation])
  
   ) as Pivot_Tbl

    RETURN ;
END;

--select * from StaticEmbelName
GO
/****** Object:  UserDefinedFunction [dbo].[CommrclCostPivotTblv2]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 --select * from CommrclCostPivotTblv2()CREATE FUNCTION [dbo].[CommrclCostPivotTblv2]( 	 )    RETURNS   @ATTTble TABLE(	[PrecostingId] [int]  NOT NULL	 	 ,[LCCost]float null,	 [PortClearing]float null,	 [Transportation]float null,	 [AllTogether]float null)ASBEGINDECLARE          @PrecostingId int,		 @LCCost float,		  @PortClearing float,		   @Transportation float,		    @AllTogether float  ,			 @Item nvarchar(max),			 @tAmount float      DECLARE CUR_TEST CURSOR FAST_FORWARD FOR    select  prcStng.PrecostingId, CmrclCst.Item ,sum((CmrclCst.Amount/12)*dbo.GetPoQuantityByOrderId(prcStng.OrderId)) as tAmount  from CommercialCosts  as CmrclCstleft join PreCostings as prcStng on prcStng.PrecostingId=CmrclCst.PrecostingId where prcStng.PrecostingId is not null group by prcStng.PrecostingId,     CmrclCst.Item                                                      OPEN CUR_TESTFETCH NEXT FROM CUR_TEST INTO @PrecostingId,@Item ,@tAmount  WHILE @@FETCH_STATUS = 0BEGIN          set  @PrecostingId=@PrecostingId	if @Item='All Together' begin set	 @AllTogether= @tAmount  end	 if @Item='Transportation' begin set	 @Transportation= @tAmount  end	  if @Item='Port & Clearing' begin set	 @PortClearing= @tAmount  end	   if @Item='LC Cost' begin set	 @LCCost= @tAmount  end	      FETCH NEXT FROM CUR_TEST INTO  @PrecostingId,@Item ,@tAmount  Insert into @ATTTble VALUES ( @PrecostingId ,		 @LCCost ,		  @PortClearing ,		   @Transportation ,		    @AllTogether   );ENDCLOSE CUR_TESTDEALLOCATE CUR_TEST      RETURN ;END;
GO
/****** Object:  UserDefinedFunction [dbo].[ConversionCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  --select * from ConversionCostPivotTbl()CREATE  FUNCTION [dbo].[ConversionCostPivotTbl]( 	 )    RETURNS   @ATTTble TABLE(	[PrecostingId] [int]  NOT NULL	 	 ,[1]float null,[2]float null,[3]float null,[4]float null,[5]float null,[6]float null,[7]float null,[8]float null,[9]float null,[10]float null,[11]float null,[12]float null,[13]float null,[14]float null,[15]float null,[16]float null,[17]float null,[18]float null,[19]float null,[20]float null,[21]float null)ASBEGINinsert into @ATTTble  select PrecostingId,[1],(case when [2] is not null then [2] else 0 end) as [2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],(case when [20] is not null then [20] else 0 end) as [20],(case when [21] is not null then [21] else 0 end) as [21] from  (select PrecostingId, ProcessId,sum(Amount) as Tamount    from ConversionCostForPreCosts where PrecostingId is not null group by   PrecostingId,ProcessId) as sourcTbl   PIVOT(   Max(Tamount) for ProcessId in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21])   ) as Pivot_Tbl    RETURN ;END;--get Process name across the id (select * from ProductionProcesses)  
GO
/****** Object:  UserDefinedFunction [dbo].[CostComponentHorizontalResult]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE  FUNCTION [dbo].[CostComponentHorizontalResult](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL,
	 
	[FabricCost] [float] NULL,
	[TrimsCost] [float] NULL,
	[EmbelCost] [float] NULL,
	[GmtsCost] [float] NULL,
	[CommlCost] [float] NULL,
	[LabTest] [float] NULL,
	[Inspection] [float] NULL,
	[Freight] [float] NULL,
	[CurrierCost] [float] NULL,
	[CertificateCost] [float] NULL,
	[DeffdLcCost] [float] NULL,
	[DesignCost] [float] NULL,
	[StudioCost] [float] NULL,
	[OpertExp] [float] NULL,
	[CMCost] [float] NULL,
	[Interest] [float] NULL,
	[IncomeTax] [float] NULL,
	[DepcAmort] [float] NULL,
	[Commission] [float] NULL,
	[TotalCost] [float] NULL,
	[PriceDzn] [float] NULL,
	[MarginDzn] [float] NULL,
	[PricePcs] [float] NULL,
	[FinalCostPcs] [float] NULL,
	[Marginpcs] [float] NULL,
	[FabricCostQprice] [float] NULL,
	[TrimsCostQprice] [float] NULL,
	[EmbelCostQprice] [float] NULL,
	[GmtsCostQprice] [float] NULL,
	[CommlCostQprice] [float] NULL,
	[LabTestQprice] [float] NULL,
	[InspectionQprice] [float] NULL,
	[FreightQprice] [float] NULL,
	[CurrierCostQprice] [float] NULL,
	[CertificateCostQprice] [float] NULL,
	[DeffdLcCostQprice] [float] NULL,
	[DesignCostQprice] [float] NULL,
	[StudioCostQprice] [float] NULL,
	[OpertExpQprice] [float] NULL,
	[CMCostQprice] [float] NULL,
	[InterestQprice] [float] NULL,
	[IncomeTaxQprice] [float] NULL,
	[DepcAmortQprice] [float] NULL,
	[CommissionQprice] [float] NULL,
	[TotalCostQprice] [float] NULL,
	[PriceDznQprice] [float] NULL,
	[MarginDznQprice] [float] NULL,
	[PricePcsQprice] [float] NULL,
	[FinalCostPcsQprice] [float] NULL,
	[MarginpcsQprice] [float] NULL
	)
AS
BEGIN

DECLARE  
        @PrecostingId int 
 
   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT PreCostingId from dbo.CostComponenetsMasterDetails 
  Group By PreCostingId
                               
                     
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @PrecostingId
 
WHILE @@FETCH_STATUS = 0
BEGIN


 INSERT INTO @ATTTble
SELECT * FROM [dbo].[ProcessCostComponentDetails](@PrecostingId)
 

   FETCH NEXT FROM CUR_TEST INTO  @PrecostingId
 
END
CLOSE CUR_TEST

DEALLOCATE CUR_TEST
 
 
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[CountComposition]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  FUNCTION [dbo].[CountComposition](
  
	 
)
    RETURNS   @ATTTble TABLE(
	[CountDeterminationId] varchar(max),
	[Composition] varchar(max)
	)
AS
BEGIN

DECLARE 
  
       
        @YarnCountDeterminationMasterId int

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    select YarnCountDeterminationMasterId from YarnCountDeterminationChilds group by YarnCountDeterminationMasterId

 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @YarnCountDeterminationMasterId
 
WHILE @@FETCH_STATUS = 0
BEGIN
DECLARE @Composition varchar(max)=''

 
Select @Composition = COALESCE(@Composition + ' ' + dbo.Compositions.CompositionName+' '+ CONVERT(varchar(100),dbo.YarnCountDeterminationChilds.Percentage)+'%', dbo.Compositions.CompositionName)
FROM            dbo.Compositions INNER JOIN
                         dbo.YarnCountDeterminationChilds ON dbo.Compositions.Id = dbo.YarnCountDeterminationChilds.CompositionId
 where  dbo.YarnCountDeterminationChilds.YarnCountDeterminationMasterId=@YarnCountDeterminationMasterId
 insert into @ATTTble values(@YarnCountDeterminationMasterId,@Composition);
   FETCH NEXT FROM CUR_TEST INTO  @YarnCountDeterminationMasterId
 
END

CLOSE CUR_TEST


DEALLOCATE CUR_TEST
    RETURN ;
END;


 
GO
/****** Object:  UserDefinedFunction [dbo].[CountriesInStringByPoId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
create  FUNCTION [dbo].[CountriesInStringByPoId](
  
	 
)
    RETURNS   @ATTTble TABLE(
	[PoId] varchar(max),
	[Countries] varchar(max)
	)
AS
BEGIN

DECLARE 
  
         @Countries varchar(max)='',
        @PoDetID varchar(max)

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    select PoDetID from TblPodetailsInfroes

 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @PoDetID
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @Countries=(select dbo.GetCountryNameInStringByPoID(@PoDetID));
 insert into @ATTTble values(@PoDetID,@Countries);
 

   FETCH NEXT FROM CUR_TEST INTO  @PoDetID
 
END
CLOSE CUR_TEST


DEALLOCATE CUR_TEST
    RETURN ;
END;




--select * from GetItemNameInStringByOrderId(1005)
GO
/****** Object:  UserDefinedFunction [dbo].[CountStripClrLengthByFabId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
Create  FUNCTION [dbo].[CountStripClrLengthByFabId] 
(	
		@PrecostingId int, 
		@FabricCostId int 
		 
)
 
RETURNS int
AS
BEGIN
DECLARE 
 @lngth int=0

 
  select @lngth=count(Id ) from StripColors where PrecostingId=@PrecostingId and FabricCostId=@FabricCostId
 --  select @lngth=count(Id ) from StripColors where PrecostingId=11034 and FabricCostId=16194
 RETURN @lngth
END
GO
/****** Object:  UserDefinedFunction [dbo].[EmbelConsumtionTotalNAvgCaluculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[EmbelConsumtionTotalNAvgCaluculation](
 
	 
) RETURNS   @EmbelSumNAvgCaltnTble TABLE(
	[EmbelCostId] [int]  NOT NULL,
	 
	[TotalCons] [float] NULL,
	[TotalRate] [float] NULL,
	[TotalAmount] [float] NULL,
	[ConsAvg] [float] NULL,
	[RateAvg] [float] NULL,
	[AmountAvg] [float] NULL 
	)
AS
BEGIN

Insert into @EmbelSumNAvgCaltnTble Select EmbelCostId,
 sum(Cons) as TotalCons,
sum(Rate) as TotalRate,
sum(Amount) as TotalAmount,

avg(Cons) as ConsAvg,
avg(Rate) as RateAvg,
avg(Amount) as AmountAvg 
   from AddConsumptionFormForEmblishmentCosts 
Group by EmbelCostId

    RETURN ;
END;
 --select * from AddConsumptionFormForEmblishmentCosts 
GO
/****** Object:  UserDefinedFunction [dbo].[EmbelCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[EmbelCostPivotTbl](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL	 
	 ,[Printing]float null,[Embroidery]float null,[SpecialWorks]float null,[GmtsDyeing]float null,[Others]float null)
AS
BEGIN
insert into @ATTTble  select PrecostingId,[Printing],[Embroidery],[SpecialWorks],[GmtsDyeing],[Others]
from
 ( select 
 prcStng.PrecostingId,
 EmblCost.EmbelName,
 
 sum(EmblCost.Rate*(dbo.GetPoQuantityByOrderId(prcStng.OrderId)/12)) as TotalAmount
  
from EmbellishmentCosts as EmblCost
left join  PreCostings as prcStng on prcStng.PrecostingId=EmblCost.PrecostingId 

where prcStng.PrecostingId is not null 

group by 
 prcStng.PrecostingId,
 EmblCost.EmbelName
 ) as sourcTbl
   PIVOT(
   Max(TotalAmount) for EmbelName in ([Printing],[Embroidery],[SpecialWorks],[GmtsDyeing],[Others])
   ) as Pivot_Tbl

    RETURN ;
END;

--get item group name across the id (select * from YarnCounts) 
GO
/****** Object:  UserDefinedFunction [dbo].[EmbelishmentWorkOrederQnty]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[EmbelishmentWorkOrederQnty] 
(	
		@embelId int
)
RETURNS DECIMAL(18,2)
AS
BEGIN
DECLARE 
 @ReqQuantity DECIMAL(18,2)=0

  SELECT @ReqQuantity=sum(ConsFromSizeQnty)
 FROM AddConsumptionFormForEmblishmentCosts where EmbelCostId=@embelId and Cons=1
GROUP BY EmbelCostId;
 
 RETURN @ReqQuantity
END
GO
/****** Object:  UserDefinedFunction [dbo].[EmbelishmentWorkOrederQntyByPoLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[EmbelishmentWorkOrederQntyByPoLevel] 
(	
		@embelId int,
		@PoId int
)
RETURNS DECIMAL(18,2)
AS
BEGIN
DECLARE 
 @ReqQuantity DECIMAL(18,2)=0

  SELECT @ReqQuantity=sum(ConsFromSizeQnty)
   FROM AddConsumptionFormForEmblishmentCosts where EmbelCostId=@embelId and Cons=1 and PoId=@PoId
GROUP BY EmbelCostId;
 
 RETURN @ReqQuantity
END
GO
/****** Object:  UserDefinedFunction [dbo].[FabricBookingAllJobQntyByBkngId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  FUNCTION [dbo].[FabricBookingAllJobQntyByBkngId](

)
  RETURNS   @TempTble TABLE(
    [BookingId] varchar(100),
    [BookingTotalJobQnty] [float]
    )
AS
BEGIN
  with cte as (select distinct p.PartialFabricBookingMasterId,p.PreCostingId,preCst.OrderId from PartialFabricBookingItemDtlsChilds p
             left join PreCostings as preCst on p.PreCostingId=preCst.PrecostingId)
            insert into  @TempTble select cte.PartialFabricBookingMasterId as BookingId, sum(ord.JobQuantity) as BookingTotalJobQnty  from cte left join 
              TblInitialOrders as ord on cte.OrderId=ord.OrderAutoID
              group by cte.PartialFabricBookingMasterId
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[FabricConsumtionTotalNAvgCaluculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FabricConsumtionTotalNAvgCaluculation](
 
	 
) RETURNS   @ATTTble TABLE(
	[FabricCostId] [int]  NOT NULL,
	 
	[TotalFinishCons] [float] NULL,
	[TotalProcessLoss] [float] NULL,
	[TotalGreyCons] [float] NULL,
	[TotalRate] [float] NULL,
	[TotalAmount] [float] NULL,
	[TotalTotalQty] [float] NULL,
	[TotalTotalAmount] [float] NULL,
	[TotalFinishConsAvg] [float] NULL,
	[TotalProcessLossAvg] [float] NULL,
	[TotalGreyConsAvg] [float] NULL,
	[TotalRateAvg] [float] NULL,
	[TotalAmountAvg] [float] NULL,
	[TotalTotalQtyAvg] [float] NULL,
	[TotalTotalAmountAvg] [float] NULL 
	 
	)
AS
BEGIN

Insert into @ATTTble Select FabricCostId,
 sum(FinishCons) as TotalFinishCons,
sum(ProcessLoss) as TotalProcessLoss,
sum(GreyCons) as TotalGreyCons,
sum(Rate) as TotalRate,
sum(Amount) as TotalAmount,
sum(TotalQty) as TotalTotalQty ,
sum(TotalAmount) as TotalTotalAmount,
avg(FinishCons) as TotalFinishConsAvg,
Avg(ProcessLoss) as TotalProcessLossAvg,
Avg(GreyCons) as TotalGreyConsAvg,
Avg(Rate) as TotalRateAvg,
Avg(Amount) as TotalAmountAvg,
Avg(TotalQty) as TotalTotalQtyAvg ,
Avg(TotalAmount) as TotalTotalAmountAvg  from ConsumptionEntryForms where FinishCons>0
Group by FabricCostId

    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[FabricCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 --select * from FabricCostPivotTbl()CREATE  FUNCTION [dbo].[FabricCostPivotTbl]( 	 )    RETURNS   @ATTTble TABLE(	[PrecostingId] [int]   NULL	 	 ,[Tamount]float null)ASBEGINinsert into @ATTTble  select PrecostingId,sum(Amount) as Tamount from FabricCosts where PreCostingId is not null Group by PrecostingId    RETURN ;END;
GO
/****** Object:  UserDefinedFunction [dbo].[FabricWiseCnspmtnBudget]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE function [dbo].[FabricWiseCnspmtnBudget](
 )
 returns @tbl Table(
 PrecostingId int not null,
 FabricCostId int not null,
 TotalCons float,
 SizeQuantity float,
 GreyCons float,
 FinishCons float
 ) 
 as begin
 with cte as (
select
      PrecostingId,
     FabricCostId,
    sum(TotalCons) as TotalCons,
   sum(SizeQuantity) as SizeQuantity,
   sum(GreyCons) as GreyCons,
   sum(FinishCons) as FinishCons
 from (select 
 prcCst.PrecostingId,
 fabCst.Id as FabricCostId,
 ((cnsmtn.SizeQuantity/12)*cnsmtn.GreyCons)/100  as TotalCons,
 cnsmtn.SizeQuantity,
 cnsmtn.GreyCons,
 cnsmtn.FinishCons
  from  FabricCosts fabCst
left join   PreCostings as prcCst on prcCst.PrecostingId= fabCst.precostingId 
left join ConsumptionEntryForms cnsmtn on cnsmtn.FabricCostId=fabCst.Id
where prcCst.PrecostingId is not null and fabCst.Id is not null
)as tbl group by 
      PrecostingId,
     FabricCostId) 
 
insert into @tbl select * from cte

return;

End
GO
/****** Object:  UserDefinedFunction [dbo].[GetColorSensitivityByFabricId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[GetColorSensitivityByFabricId] 
(	
		@FabricId int
)
RETURNS varchar(max)
AS
BEGIN
DECLARE 
  @Colors varchar(max)='',
        @color varchar(max)

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT ContrastColor from FabricColorSensitivities where FabricId=@FabricId
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @color
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @Colors=@Colors+@color+','
 

   FETCH NEXT FROM CUR_TEST INTO  @color
 
END
CLOSE CUR_TEST


DEALLOCATE CUR_TEST
 
 RETURN @Colors
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetContrastOrFabricColorByFabricIdNItemId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE FUNCTION [dbo].[GetContrastOrFabricColorByFabricIdNItemId] 
(	
		@FabricId int,
		@itemId int,
		@color nvarchar(max)
)
RETURNS varchar(max)
AS
BEGIN
DECLARE 
  @Colors varchar(max)='' 

    
    SELECT @Colors=ContrastColor from FabricColorSensitivities
	where FabricId=@FabricId and ItemId=@itemId and Color=@color
  


 
 RETURN @Colors
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetCountryNameInStringByPoID]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE FUNCTION [dbo].[GetCountryNameInStringByPoID] 
(	
		@PoDetID int
)
RETURNS varchar(max)
AS
BEGIN
DECLARE 
  
         @Countries varchar(max)='',
        @Country varchar(max)

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    select cntry.Region_Name from PreCostings as preCst
 left join TblInitialOrders as ord on preCst.OrderId=ord.OrderAutoID
  left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID 
 left join TblRegionInfoes as cntry on inptPnnl.CountryID =cntry.RegionID where PoDetID=@PoDetID
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @Country
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @Countries=@Countries+@Country+','
 
 

   FETCH NEXT FROM CUR_TEST INTO  @Country
 
END
CLOSE CUR_TEST


DEALLOCATE CUR_TEST
 
 RETURN @Countries
END

GO
/****** Object:  UserDefinedFunction [dbo].[getEmbelBookingQnty]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE  FUNCTION [dbo].[getEmbelBookingQnty](
 @BookingNo varchar(100)
	 
)
    RETURNS   @ATTTble TABLE(
	[woNo] varchar(100),
	[BookingQnty] [float]
 
	)
AS
BEGIN
 Declare  @ATTTbleTst TABLE(
	[woNo] varchar(100),
	[OrderAutoId] [int] NULL,
	[BookingQnty] [float]
 
	)
DECLARE @woNo varchar(max)='',
        @OrderAutoId int ,
		@BookingQnty decimal(8,2)=0.00

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
   Select embel.WoNo ,embelChild.OrderAutoId from MultipleJobWiseEmbellishmentWorkOrders as embel 
 left join EmbellishmentWODetailsChilds embelChild on embelChild.EmbellishmentMasterId= embel.Id  
 where OrderAutoId is not null group by embel.WoNo, embelChild.OrderAutoId
 

OPEN CUR_TEST
FETCH 
 FROM CUR_TEST INTO @woNo,@OrderAutoId
 
WHILE @@FETCH_STATUS = 0
BEGIN
set @BookingQnty=dbo.GetPoQuantityByOrderId(@OrderAutoId);

 INSERT INTO @ATTTbleTst values (@woNo,@OrderAutoId,@BookingQnty);
  
 

   FETCH NEXT FROM CUR_TEST INTO  @woNo,@OrderAutoId
 
END
CLOSE CUR_TEST

DEALLOCATE CUR_TEST

 INSERT INTO @ATTTble select woNo,sum(BookingQnty) as BookingQnty from @ATTTbleTst where woNo=@BookingNo group by woNo
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetEmbelCostTotalQtyByEmbelCostNPoId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  FUNCTION [dbo].[GetEmbelCostTotalQtyByEmbelCostNPoId](

	 
)
    RETURNS   @ATTTble TABLE(
	[EmbelCostId] int not null,  
	[PoId] int not null, 
	[TotalQty] decimal(18,4) 
	)
AS
BEGIN

 

 INSERT INTO @ATTTble  select EmbelCostId,PoId,sum(Cons) as TotalQty  from AddConsumptionFormForEmblishmentCosts   group by EmbelCostId,PoId


    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[getEmbelTotalBookingQnty]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE  FUNCTION [dbo].[getEmbelTotalBookingQnty](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[woNo] varchar(max),
	[TotalBookingQnty] [float]
 
	)
AS
BEGIN
  Declare  @ATTTbleTst TABLE(
	[woNo] varchar(100),
	[OrderAutoId] [int] NULL,
	[BookingQnty] [float]
 
	)
DECLARE @woNo varchar(max)='',
        @OrderAutoId int ,
		@BookingQnty decimal(8,2)=0.00

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
   select embelChild.OrderAutoId,WoNo  from MultipleJobWiseEmbellishmentWorkOrders as embel  
 left join   EmbellishmentWODetailsChilds embelChild on 
 embelChild.EmbellishmentMasterId= embel.Id  group by embelChild.OrderAutoId,WoNo 
 

OPEN CUR_TEST
FETCH 
 FROM CUR_TEST INTO @OrderAutoId,@woNo
 
WHILE @@FETCH_STATUS = 0
BEGIN
set @BookingQnty=dbo.GetPoQuantityByOrderId(@OrderAutoId);

 INSERT INTO @ATTTbleTst values (@woNo,@OrderAutoId,@BookingQnty);
  
 

   FETCH NEXT FROM CUR_TEST INTO  @OrderAutoId,@woNo
 
END
CLOSE CUR_TEST

DEALLOCATE CUR_TEST
 
 INSERT INTO @ATTTble select woNo,sum(BookingQnty) as BookingQnty from @ATTTbleTst   group by woNo
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[getEmblBookingQnty]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 Create  FUNCTION [dbo].[getEmblBookingQnty](
 @BookingNoId int
	 
)
    RETURNS   @ATTTble TABLE(
	[woNoId] varchar(100),
	[BookingQnty] [float]
 
	)
AS
BEGIN
 Declare  @ATTTbleTst TABLE(
	[woNoId] varchar(100),
	[OrderAutoId] [int] NULL,
	[BookingQnty] [float]
 
	)
DECLARE @woNoId int=0,
        @OrderAutoId int ,
		@BookingQnty decimal(8,2)=0.00

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
   Select embl.Id,emblChild.OrderAutoId  from MultipleJobWiseEmbellishmentWorkOrders as embl 
 left join EmbellishmentWODetailsChilds emblChild on emblChild.EmbellishmentMasterId= embl.Id 
 where OrderAutoId is not null group by embl.Id ,emblChild.OrderAutoId
 

OPEN CUR_TEST
FETCH 
 FROM CUR_TEST INTO @woNoId,@OrderAutoId
 
WHILE @@FETCH_STATUS = 0
BEGIN
set @BookingQnty=dbo.GetPoQuantityByOrderId(@OrderAutoId);

 INSERT INTO @ATTTbleTst values (@woNoId,@OrderAutoId,@BookingQnty);
  
 

   FETCH NEXT FROM CUR_TEST INTO  @woNoId,@OrderAutoId
 
END
CLOSE CUR_TEST

DEALLOCATE CUR_TEST

 INSERT INTO @ATTTble select woNoId,sum(BookingQnty) as BookingQnty from @ATTTbleTst where woNoId=@BookingNoId group by woNoId
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetFabricBookingAllStyleRefNo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
 
CREATE FUNCTION [dbo].[GetFabricBookingAllStyleRefNo] 
(	
		@PartialFabricBookingMasterId int
)
RETURNS varchar(max)
AS
BEGIN
DECLARE 
 @styleRef varchar(max)=''
  select  @styleRef= STRING_AGG (Style_Ref, ',') from(select 
 ord.Style_Ref,
 bookinChild.PartialFabricBookingMasterId
 from
PartialFabricBookingItemDtlsChilds bookinChild  
  --left join  FabricCosts as fabCost on fabCost.Id=bookinChild.FabricCostId
 left join PreCostings as preCst on preCst.PrecostingId=bookinChild.PrecostingId 
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
  where  bookinChild.PartialFabricBookingMasterId=@PartialFabricBookingMasterId
 group by  ord.Style_Ref,bookinChild.PartialFabricBookingMasterId) as tbl group by PartialFabricBookingMasterId 
 --print(@styleRef)
 RETURN @styleRef
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetFabricBookingJObQty]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE FUNCTION [dbo].[GetFabricBookingJObQty] (			@PrecostingId int)RETURNS DECIMAL(18,2)ASBEGINDECLARE  @PoQuantity DECIMAL(18,2)=0Select top(1) @PoQuantity=jQty from (select   sum(dbo.GetPoQuantityByOrderId(ord.OrderAutoID)) as jQty, preCst.PrecostingId from --PartialFabricBookings as booking -- left join PartialFabricBookingItemDtlsChilds bookinChild on bookinChild.PartialFabricBookingMasterId= booking.Id  --left join  FabricCosts as fabCost on fabCost.Id=bookinChild.FabricCostId  PreCostings as preCst  left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID  where  preCst.PrecostingId=@PrecostingId group by preCst.PrecostingId) as tbl  RETURN @PoQuantityEND
GO
/****** Object:  UserDefinedFunction [dbo].[GetFabricConsumtionCstByFabricIdNColor]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  FUNCTION [dbo].[GetFabricConsumtionCstByFabricIdNColor] 
(	
		@CnsmptnId int
		 
)
--RETURNS DECIMAL(18,2)
RETURNS float
AS
BEGIN
DECLARE 
 @TotalFinisCons float=0
 --select @TotalFinisCons= sum((Qty/12)*FinishCons) from(

  select  @TotalFinisCons=((SizeQuantity/12)*FinishCons)  from ConsumptionEntryForms
  where  Id=@CnsmptnId
  --PrecostingId=@PrecostingId and
 --FinishCons>0 and FabricCostId=@fabCostId and  dbo.TRIM(Color)=dbo.TRIM(@Color)
-- group by  PrecostingId,FabricCostId,dbo.TRIM(Color),FinishCons) as fabCnsmption group by FabricCostId
 
 --select @TotalFinisCons= sum((Qty/12)*FinishCons) from(
 -- select PrecostingId,FabricCostId,trim(Color) as Color,FinishCons,sum(SizeQuantity) as Qty from ConsumptionEntryForms
 -- where  PrecostingId=@PrecostingId and
 --FinishCons>0 and FabricCostId=@fabCostId and  trim(Color)=trim(@Color)
 --group by  PrecostingId,FabricCostId,trim(Color),FinishCons) as fabCnsmption group by FabricCostId
 
 --select PrecostingId,FabricCostId,trim(Color) as Color,FinishCons,sum(SizeQuantity) as Qty from ConsumptionEntryForms where  PrecostingId=5019 and
 --FinishCons>0 and FabricCostId=9067 and  trim(Color)='I.14-6011 TCX'
 --group by  PrecostingId,FabricCostId,trim(Color),FinishCons

--  SELECT @TotalFinisCons=sum(PO_Quantity) 
--FROM TblPodetailsInfroes where InitialOrderID=@OrderId
--GROUP BY InitialOrderID;
 
 RETURN @TotalFinisCons
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetFabricConsumtionCstForYarnByFabricId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE  FUNCTION [dbo].[GetFabricConsumtionCstForYarnByFabricId] 
(	
		@CnsmptnId int 
		--@fabCostId int 
		 
)
--RETURNS DECIMAL(18,2)
RETURNS float
AS
BEGIN
DECLARE 
 @TotalGreyCons float=0

 
  select  @TotalGreyCons=((SizeQuantity/12)*GreyCons)  from ConsumptionEntryForms
  where  Id=@CnsmptnId
 --select @PoQuantity= sum((Qty/12)*GreyCons) from( -- select PrecostingId,FabricCostId,dbo.TRIM(Color) as Color,GreyCons,sum(SizeQuantity) as Qty from ConsumptionEntryForms -- where  PrecostingId=@PrecostingId and --FinishCons>0 and FabricCostId=@fabCostId   --group by  PrecostingId,FabricCostId,dbo.TRIM(Color),GreyCons) as fabCnsmption group by FabricCostId 
 --select @PoQuantity= sum((Qty/12)*FinishCons) from(
 -- select PrecostingId,FabricCostId,trim(Color) as Color,FinishCons,sum(SizeQuantity) as Qty from ConsumptionEntryForms
 -- where  PrecostingId=@PrecostingId and
 --FinishCons>0 and FabricCostId=@fabCostId and  trim(Color)=trim(@Color)
 --group by  PrecostingId,FabricCostId,trim(Color),FinishCons) as fabCnsmption group by FabricCostId
 
 --select PrecostingId,FabricCostId,trim(Color) as Color,FinishCons,sum(SizeQuantity) as Qty from ConsumptionEntryForms where  PrecostingId=5019 and
 --FinishCons>0 and FabricCostId=9067 and  trim(Color)='I.14-6011 TCX'
 --group by  PrecostingId,FabricCostId,trim(Color),FinishCons

--  SELECT @PoQuantity=sum(PO_Quantity) 
--FROM TblPodetailsInfroes where InitialOrderID=@OrderId
--GROUP BY InitialOrderID;
 
 RETURN @TotalGreyCons
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetFabricConsumtionCstGrayFabByFabricIdNColor]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE  FUNCTION [dbo].[GetFabricConsumtionCstGrayFabByFabricIdNColor] 
(	
		@PrecostingId int,
		@fabCostId int,
		@Color varchar(max)
)
RETURNS float
AS
BEGIN
DECLARE 
 @GreyConsQuantity float=0
 select @GreyConsQuantity= sum((FinishCons*100)/(100-ProcessLoss)) from(  select PrecostingId,FabricCostId,dbo.TRIM(Color) as Color,sum(FinishCons) as FinishCons,ProcessLoss,sum(SizeQuantity) as Qty from ConsumptionEntryForms  where  PrecostingId=@PrecostingId and GreyCons>0 and FabricCostId=@fabCostId and  dbo.TRIM(Color)=dbo.TRIM(@Color) group by  PrecostingId,FabricCostId,dbo.TRIM(Color),FinishCons,ProcessLoss) as fabCnsmption group by FabricCostId 
 --select @PoQuantity= sum((Qty/12)*FinishCons) from(
 -- select PrecostingId,FabricCostId,trim(Color) as Color,FinishCons,sum(SizeQuantity) as Qty from ConsumptionEntryForms
 -- where  PrecostingId=@PrecostingId and
 --FinishCons>0 and FabricCostId=@fabCostId and  trim(Color)=trim(@Color)
 --group by  PrecostingId,FabricCostId,trim(Color),FinishCons) as fabCnsmption group by FabricCostId
 
 --select PrecostingId,FabricCostId,trim(Color) as Color,sum(FinishCons) as FinishCons,ProcessLoss,sum(SizeQuantity) as Qty from ConsumptionEntryForms where  PrecostingId=5019 and
 --FinishCons>0 and FabricCostId=9067 and  trim(Color)='I.14-6011 TCX'
 --group by  PrecostingId,FabricCostId,trim(Color),FinishCons,ProcessLoss

--  SELECT @PoQuantity=sum(PO_Quantity) 
--FROM TblPodetailsInfroes where InitialOrderID=@OrderId
--GROUP BY InitialOrderID;
 
 RETURN @GreyConsQuantity
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetFabricPurchaseCostByPrecostingId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE  FUNCTION [dbo].[GetFabricPurchaseCostByPrecostingId](

)
    RETURNS   @Tble TABLE(
	[PreCostingId] int not null,
	[FabricSourceId] int null,
	[FabricPurchaseAmount] float null
 
	)
AS
BEGIN
 insert into @Tble select PreCostingId,FabricSourceId,sum(Amount) as FabricPurchaseAmount from FabricCosts where PreCostingId is not null
  group by PreCostingId,FabricSourceId
  
  return;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetGmtsColorByFabricIdNItemId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
Create FUNCTION [dbo].[GetGmtsColorByFabricIdNItemId] 
(	
		@FabricId int,
		@itemId int
)
RETURNS varchar(max)
AS
BEGIN
DECLARE 
  @Colors varchar(max)='' 

    
    SELECT @Colors=Color from FabricColorSensitivities where FabricId=@FabricId and ItemId=@itemId
  


 
 RETURN @Colors
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetItemNameInStringByOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
Create  FUNCTION [dbo].[GetItemNameInStringByOrderId](
  @orderId int 
	 
)
    RETURNS   @ATTTble TABLE(
	[Items] varchar(max)   
	)
AS
BEGIN

DECLARE  
         @Items varchar(max)='',
        @Item varchar(max)
		--left join ItemDetailsOrderEntries  on PreCstng.OrderId=ItemDetailsOrderEntries.order_entry_id 
--left join GarmentsItemEntries  on ItemDetailsOrderEntries.item=GarmentsItemEntries.Id
--left join GarmentsItemEntries  on ItemDetailsOrderEntries.item=GarmentsItemEntries.Id
   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT GarmentsItemEntries.ItemName from PreCostings as PreCstng  
	left join ItemDetailsOrderEntries as itemdtls on PreCstng.OrderId=itemdtls.order_entry_id 
	left join GarmentsItemEntries  on itemdtls.item=GarmentsItemEntries.Id
	where OrderId=@orderId
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @Item
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @Items=@Items+@Item+','
 

   FETCH NEXT FROM CUR_TEST INTO  @Item
 
END
CLOSE CUR_TEST

 INSERT INTO @ATTTble values (@Items)


DEALLOCATE CUR_TEST
 
 
    RETURN ;
END;




--select * from GetItemNameInStringByOrderId(1005)
GO
/****** Object:  UserDefinedFunction [dbo].[GetItemNColorNSizeByPoId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create FUNCTION [dbo].[GetItemNColorNSizeByPoId](
 
	 
) RETURNS   @Tbl TABLE(
	[PoId] [int]  NOT NULL,
	[ItemId] [int] NULL,
	[Color] varchar(100),
	[Size] varchar(100) 
	)
AS
BEGIN

Insert into @Tbl Select PoId,ItemId,Color,Size
 
   from SizePannelPodetails 
   where PoId is not null
Group by PoId,ItemId,Color,Size

    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetOrg_Shipment_DateInStringByOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE  FUNCTION [dbo].[GetOrg_Shipment_DateInStringByOrderId](
  @orderId int 
	 
)
    RETURNS   @ATTTble TABLE(
	[OrderId] int not null,
	[Org_Shipment_Dates] varchar(max)
	)
AS
BEGIN

DECLARE  
         @Org_Shipment_Dates varchar(max)='',
        @Org_Shipment_Date varchar(max)
 
   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT  Org_Shipment_Date   from TblPodetailsInfroes where InitialOrderID=@orderId group by Org_Shipment_Date 
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @Org_Shipment_Date
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @Org_Shipment_Dates=@Org_Shipment_Dates+@Org_Shipment_Date+','
 

   FETCH NEXT FROM CUR_TEST INTO  @Org_Shipment_Date
 
END
CLOSE CUR_TEST

 INSERT INTO @ATTTble values (@orderId,@Org_Shipment_Dates)


DEALLOCATE CUR_TEST
 
 
    RETURN ;
END;

GO
/****** Object:  UserDefinedFunction [dbo].[GetPercentage]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE  FUNCTION [dbo].[GetPercentage] 
(	
		@value float,
		@percentage float 
		 
)
RETURNS DECIMAL(18,2)
--RETURNS float
AS
BEGIN
DECLARE 
 @result DECIMAL(18,2)=0
  
set @result=(@value/100)*@percentage
 RETURN @result
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetPoNoNameInStringByOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE  FUNCTION [dbo].[GetPoNoNameInStringByOrderId](
  @orderId int 
	 
)
    RETURNS   @ATTTble TABLE(
	[OrderId] int not null,
	[PoNumbers] varchar(max)
	)
AS
BEGIN

DECLARE  
         @PoNumbers varchar(max)='',
        @PoNumber varchar(max),
		
		@InitialOrderID int 
 
   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT PO_No,InitialOrderID from TblPodetailsInfroes where InitialOrderID=@orderId
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @PoNumber,@InitialOrderID
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @PoNumbers=@PoNumbers+@PoNumber+','
 

   FETCH NEXT FROM CUR_TEST INTO  @PoNumber,@InitialOrderID
 
END
CLOSE CUR_TEST

 INSERT INTO @ATTTble values (@InitialOrderID,@PoNumbers)


DEALLOCATE CUR_TEST
 
 
    RETURN ;
END;

GO
/****** Object:  UserDefinedFunction [dbo].[GetPoQuantityByOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[GetPoQuantityByOrderId] 
(	
		@OrderId int
)
RETURNS DECIMAL(18,2)
AS
BEGIN
DECLARE 
 @PoQuantity DECIMAL(18,2)=0

  SELECT @PoQuantity=sum(PO_Quantity) 
FROM TblPodetailsInfroes where InitialOrderID=@OrderId
GROUP BY InitialOrderID;
 
 RETURN @PoQuantity
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetStripColorByFabricId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[GetStripColorByFabricId] 
(	
		@FabricId int
)
RETURNS varchar(max)
AS
BEGIN
DECLARE 
  @Colors varchar(max)='',
        @color varchar(max)

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT StripColor from StripColors where FabricCostId=@FabricId
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @color
 
WHILE @@FETCH_STATUS = 0
BEGIN


set @Colors=@Colors+@color+','
 

   FETCH NEXT FROM CUR_TEST INTO  @color
 
END
CLOSE CUR_TEST


DEALLOCATE CUR_TEST
 
 RETURN @Colors
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetStripeCstForYarnByCnsId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
Create  FUNCTION [dbo].[GetStripeCstForYarnByCnsId] 
(	
		@CnsmptnId int, 
		@Cons float 
		 
)
--RETURNS DECIMAL(18,2)
RETURNS float
AS
BEGIN
DECLARE 
 @TotalGreyCons float=0

 
  select  @TotalGreyCons=((SizeQuantity/12)*@Cons)  from ConsumptionEntryForms
  where  Id=@CnsmptnId
  
 RETURN @TotalGreyCons
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetStripTotalMesurment]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	create FUNCTION  [dbo].[GetStripTotalMesurment] 
(
	@fabricCostId int
	 
)
RETURNS float
AS
BEGIN
DECLARE 
		   @TotalCons float=0
  
  
 select  @TotalCons=sum(Measurement) from StripColors where FabricCostId=@fabricCostId

 return @TotalCons;
End
GO
/****** Object:  UserDefinedFunction [dbo].[GetTrimCostTotalQtyByTrimCostNPoId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
create  FUNCTION [dbo].[GetTrimCostTotalQtyByTrimCostNPoId](

	 
)
    RETURNS   @ATTTble TABLE(
	[TrimCostId] int not null,  
	[PoNoId] int not null, 
	[TotalQty] decimal(18,4) 
	)
AS
BEGIN

 

 INSERT INTO @ATTTble  select TrimCostId,PoNoId,sum(TotalQty) from ConsumptionEntryFormForTrimsCosts   group by TrimCostId,PoNoId


    RETURN ;
END;




--select * from GetItemNameInStringByOrderId(1005)
GO
/****** Object:  UserDefinedFunction [dbo].[getTrimsBookingQnty]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE  FUNCTION [dbo].[getTrimsBookingQnty](
 @BookingNoId int
	 
)
    RETURNS   @ATTTble TABLE(
	[woNoId] varchar(100),
	[BookingQnty] [float]
 
	)
AS
BEGIN
 Declare  @ATTTbleTst TABLE(
	[woNoId] varchar(100),
	[OrderAutoId] [int] NULL,
	[BookingQnty] [float]
 
	)
DECLARE @woNoId int=0,
        @OrderAutoId int ,
		@BookingQnty decimal(8,2)=0.00

   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
   Select trims.Id,trimsChild.OrderAutoId  from MultipleJobWiseTrimsBookingV2 as trims 
 left join TrimsBookingItemDtlsChilds trimsChild on trimsChild.TrimsBookingMasterId= trims.Id 
 where OrderAutoId is not null group by trims.Id ,trimsChild.OrderAutoId
 

OPEN CUR_TEST
FETCH 
 FROM CUR_TEST INTO @woNoId,@OrderAutoId
 
WHILE @@FETCH_STATUS = 0
BEGIN
set @BookingQnty=dbo.GetPoQuantityByOrderId(@OrderAutoId);

 INSERT INTO @ATTTbleTst values (@woNoId,@OrderAutoId,@BookingQnty);
  
 

   FETCH NEXT FROM CUR_TEST INTO  @woNoId,@OrderAutoId
 
END
CLOSE CUR_TEST

DEALLOCATE CUR_TEST

 INSERT INTO @ATTTble select woNoId,sum(BookingQnty) as BookingQnty from @ATTTbleTst where woNoId=@BookingNoId group by woNoId
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[InitialConsumtionFunction]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[InitialConsumtionFunction](
 
	 
) RETURNS   @Tbl TABLE(
	[PrecostingId] [int]  NOT NULL,
	[JobNo] nvarchar(100) NULL,
	[OrderAutoID] int null,
	[PO_No] nvarchar(100) NULL,
	[PoDetID] int null,
	[item] int null,
	[ItemName] varchar (100),
	[CountryID] int null,
	[Region_Name] varchar(100),
	[Size] varchar(100),
	[Color] varchar (100),
	[JobQnty] float,
	[PoQuanity] float,
	[CountryQnty] float,
	[sizeQnty] float

	)
AS
BEGIN


Insert into @Tbl Select 
	preCst.PrecostingId,JobNo,OrderAutoID,PO_No,PoDetID,szeWiseBrkdwn.ItemId,GarmentsItemEntries.ItemName,
	inptPnnl.CountryID,cntry.Region_Name,Size,Color,
	dbo.GetPoQuantityByOrderId(OrderAutoID) as JobQnty,
	sum(PO_Quantity) as PoQuanity,
	 sum(inptPnnl.Quantity) as CountryQnty,
	sum(szeWiseBrkdwn.Quanity) as sizeQnty

 from PreCostings as preCst
 left join TblInitialOrders as ord on preCst.OrderId=ord.OrderAutoID
  left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 --left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id
 left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID 
 left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID
 left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
 left join GarmentsItemEntries on szeWiseBrkdwn.ItemId=GarmentsItemEntries.Id
 left join TblRegionInfoes as cntry on inptPnnl.CountryID =cntry.RegionID
  where  preCst.PrecostingId is not null and size is not null and Color is not null
	 group by  
	preCst.PrecostingId,JobNo,OrderAutoID, PO_No,PoDetID,szeWiseBrkdwn.ItemId,GarmentsItemEntries.ItemName,inptPnnl.CountryID,cntry.Region_Name,Size,Color

	Order by  PoDetID

    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[IsBTBMarginLcExistInLcNbtbCommunicator]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
Create FUNCTION [dbo].[IsBTBMarginLcExistInLcNbtbCommunicator] 
(	
		@BTBMarginLcId int
)
RETURNS int
AS
BEGIN

 RETURN (select (CASE WHEN count(Id)>0  THEN 1 ELSE 0 END)
from LcEntryNBtbLcCommunicator
where BtbLcId=@BTBMarginLcId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsConsumptionIdExist]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
CREATE FUNCTION [dbo].[IsConsumptionIdExist] 
(	
		@ConsumptinId int
)
RETURNS int
AS
BEGIN

 RETURN (select (CASE WHEN count(Id)>0  THEN 1 ELSE 0 END)
from TrimsBookingItemDtlsChilds
where ConsumptionId=@ConsumptinId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsTrimCostIdExist]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
-- Create Inline Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
 
create FUNCTION [dbo].[IsTrimCostIdExist] 
(	
		@TrimCostId int
)
RETURNS int
AS
BEGIN

 RETURN (select (CASE WHEN count(Id)>0  THEN 1 ELSE 0 END)
from TrimsBookingItemDtlsChilds
where TrimCostId=@TrimCostId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[PrecstingBudgetPriceIndivitualPercetage]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[PrecstingBudgetPriceIndivitualPercetage] 
(
	@BudgetCost DECIMAL(18,2),
	@TotalCost DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
DECLARE 
		   @BasedOn DECIMAL(18,2)
  
 set @BasedOn=@BudgetCost*100/@TotalCost;

 return @BasedOn;
End
GO
/****** Object:  UserDefinedFunction [dbo].[PrecstingtTotalConsCalculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE FUNCTION  [dbo].[PrecstingtTotalConsCalculation] 
(
	@QntyDzn DECIMAL(18,4),
	@OrderQnty DECIMAL(18,4)
)
RETURNS DECIMAL(18,4)
AS
BEGIN
DECLARE 
		   @TotalCons DECIMAL(18,4)
  
 set @TotalCons=(@OrderQnty/12)*@QntyDzn;
   --totCons=(2.2554/12)*32600
   --totCons=(32600/12)*2.2544
 return @TotalCons;
End
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessCostComponentDetails]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ProcessCostComponentDetails](
 
	@PrecostingKey int
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL,
	 
	[FabricCost] [float] NULL,
	[TrimsCost] [float] NULL,
	[EmbelCost] [float] NULL,
	[GmtsCost] [float] NULL,
	[CommlCost] [float] NULL,
	[LabTest] [float] NULL,
	[Inspection] [float] NULL,
	[Freight] [float] NULL,
	[CurrierCost] [float] NULL,
	[CertificateCost] [float] NULL,
	[DeffdLcCost] [float] NULL,
	[DesignCost] [float] NULL,
	[StudioCost] [float] NULL,
	[OpertExp] [float] NULL,
	[CMCost] [float] NULL,
	[Interest] [float] NULL,
	[IncomeTax] [float] NULL,
	[DepcAmort] [float] NULL,
	[Commission] [float] NULL,
	[TotalCost] [float] NULL,
	[PriceDzn ] [float] NULL,
	[MarginDzn] [float] NULL,
	[PricePcs] [float] NULL,
	[FinalCostPcs] [float] NULL,
	[Marginpcs] [float] NULL,

	[FabricCostQprice] [float] NULL,
	[TrimsCostQprice] [float] NULL,
	[EmbelCostQprice] [float] NULL,
	[GmtsCostQprice] [float] NULL,
	[CommlCostQprice] [float] NULL,
	[LabTestQprice] [float] NULL,
	[InspectionQprice] [float] NULL,
	[FreightQprice] [float] NULL,
	[CurrierCostQprice] [float] NULL,
	[CertificateCostQprice] [float] NULL,
	[DeffdLcCostQprice] [float] NULL,
	[DesignCostQprice] [float] NULL,
	[StudioCostQprice] [float] NULL,
	[OpertExpQprice] [float] NULL,
	[CMCostQprice] [float] NULL,
	[InterestQprice] [float] NULL,
	[IncomeTaxQprice] [float] NULL,
	[DepcAmortQprice] [float] NULL,
	[CommissionQprice] [float] NULL,
	[TotalCostQprice] [float] NULL,
	[PriceDznQprice] [float] NULL,
	[MarginDznQprice] [float] NULL,
	[PricePcsQprice] [float] NULL,
	[FinalCostPcsQprice] [float] NULL,
	[MarginpcsQprice] [float] NULL
	)
AS
BEGIN

DECLARE  
        @PrecostingId int,
		 @FabricCost float,
		  @TrimsCost float,
		   @EmbelCost float,
		    @GmtsCost float,
			 @CommlCost float,
			  @LabTest float,
			   @Inspection float,
			    @Freight float,
				 @CurrierCost float,
				  @CertificateCost float,
				   @DeffdLcCost float,
				    @DesignCost float,
					 @StudioCost float,
					  @OpertExp float,
					   @CMCost float,
					    @Interest float,
						 @IncomeTax float,
						  @DepcAmort float,
						   @Commission float,
						    @TotalCost float,
							 @PriceDzn float,
							  @MarginDzn float,
							   @PricePcs float,
							    @FinalCostPcs float,
								 @Marginpcs float,
		@FabricCostQprice float,
		  @TrimsCostQprice float,
		   @EmbelCostQprice float,
		    @GmtsCostQprice float,
			 @CommlCostQprice float,
			  @LabTestQprice float,
			   @InspectionQprice float,
			    @FreightQprice float,
				 @CurrierCostQprice float,
				  @CertificateCostQprice float,
				   @DeffdLcCostQprice float,
				    @DesignCostQprice float,
					 @StudioCostQprice float,
					  @OpertExpQprice float,
					   @CMCostQprice float,
					    @InterestQprice float,
						 @IncomeTaxQprice float,
						  @DepcAmortQprice float,
						   @CommissionQprice float,
						    @TotalCostQprice float,
							 @PriceDznQprice float,
							  @MarginDznQprice float,
							   @PricePcsQprice float,
							    @FinalCostPcsQprice float,
								 @MarginpcsQprice float,

								 @CostComponetId int,
								 @BudgetedCost  float ,
								   @QPrice  float 
 
   DECLARE CUR_TEST CURSOR FAST_FORWARD FOR
    SELECT CostComponetId,BudgetedCost,PreCostingId,QPrice
  from  CostComponenetsMasterDetails   where PreCostingId=@PrecostingKey ORDER BY CostComponetId ASC
                               
                     
 
OPEN CUR_TEST
FETCH NEXT FROM CUR_TEST INTO @CostComponetId,@BudgetedCost ,@PrecostingId,@QPrice
 
WHILE @@FETCH_STATUS = 0
BEGIN
   Declare @startTime  time;
   
   
  set  @PrecostingId=@PrecostingId
	if @CostComponetId=1 begin set	 @FabricCost= @BudgetedCost set	 @FabricCostQprice= @QPrice end
	if @CostComponetId=2  begin set	  @TrimsCost=@BudgetedCost   set	  @TrimsCostQprice=@QPrice end
	if @CostComponetId=3 begin set   @EmbelCost =@BudgetedCost   set  @EmbelCostQprice =@QPrice end
	if @CostComponetId=4 begin set  @GmtsCost =@BudgetedCost     set  @GmtsCostQprice =@QPrice end
	if @CostComponetId=5 begin set	 @CommlCost=@BudgetedCost    set	 @CommlCostQprice=@QPrice end
	if @CostComponetId=6 begin set	  @LabTest=@BudgetedCost     set	  @LabTestQprice=@QPrice end
	if @CostComponetId=7 begin set   @Inspection =@BudgetedCost   set   @InspectionQprice =@QPrice end
	if @CostComponetId=8 begin set    @Freight=@BudgetedCost      set    @FreightQprice=@QPrice  end
	if @CostComponetId=9 begin set	 @CurrierCost =@BudgetedCost  set	 @CurrierCostQprice =@QPrice end
	if @CostComponetId=10 begin set  @CertificateCost=@BudgetedCost  set  @CertificateCostQprice=@QPrice end
	if @CostComponetId=11 begin set   @DeffdLcCost =@BudgetedCost    set   @DeffdLcCostQprice =@QPrice  end
	if @CostComponetId=12 begin set    @DesignCost =@BudgetedCost     set    @DesignCostQprice =@QPrice  end
	if @CostComponetId=13 begin set	 @StudioCost =@BudgetedCost     set	 @StudioCostQprice =@QPrice end
	if @CostComponetId=14 begin set  @OpertExp =@BudgetedCost         set  @OpertExpQprice =@QPrice end
	if @CostComponetId=15 begin  set  @CMCost=@BudgetedCost         set  @CMCostQprice=@QPrice end
	if @CostComponetId=16 begin	 set   @Interest=@BudgetedCost     set   @InterestQprice=@QPrice end
	if @CostComponetId=17 begin	set	 @IncomeTax=@BudgetedCost      set	 @IncomeTaxQprice=@QPrice end
	if @CostComponetId=18 begin	set	  @DepcAmort =@BudgetedCost     set	  @DepcAmortQprice =@QPrice end
	if @CostComponetId=19 begin	set	   @Commission=@BudgetedCost     set	   @CommissionQprice=@QPrice end
	if @CostComponetId=20 begin	set    @TotalCost =@BudgetedCost     set    @TotalCostQprice =@QPrice end
	if @CostComponetId=21 begin	set	 @PriceDzn=@BudgetedCost        set	 @PriceDznQprice=@QPrice end
	if @CostComponetId=22 begin	set	  @MarginDzn =@BudgetedCost      set	  @MarginDznQprice =@QPrice end
	if @CostComponetId=23 begin	set   @PricePcs=@BudgetedCost       set   @PricePcsQprice=@QPrice end
	if @CostComponetId=24 begin	set    @FinalCostPcs=@BudgetedCost    set    @FinalCostPcsQprice=@QPrice end
	if @CostComponetId=25 begin	set	 @Marginpcs =@BudgetedCost       set	 @MarginpcsQprice =@QPrice end
 
  


   FETCH NEXT FROM CUR_TEST INTO  @CostComponetId,@BudgetedCost,@PrecostingId ,@QPrice
 
END
CLOSE CUR_TEST
Insert into @ATTTble
 VALUES ( @PrecostingId  ,
		 @FabricCost, 
		  @TrimsCost,
		   @EmbelCost ,
		    @GmtsCost ,
			 @CommlCost ,
			  @LabTest,
			   @Inspection ,
			    @Freight,
				 @CurrierCost ,
				  @CertificateCost ,
				   @DeffdLcCost ,
				    @DesignCost ,
					 @StudioCost ,
					  @OpertExp ,
					   @CMCost,
					    @Interest ,
						 @IncomeTax,
						  @DepcAmort ,
						   @Commission,
						    @TotalCost ,
							 @PriceDzn,
							  @MarginDzn ,
							   @PricePcs,
							    @FinalCostPcs,
								 @Marginpcs ,
								 @FabricCostQprice,
	@TrimsCostQprice,
	@EmbelCostQprice,
	@GmtsCostQprice,
	@CommlCostQprice,
	@LabTestQprice,
	@InspectionQprice,
	@FreightQprice,
	@CurrierCostQprice,
	@CertificateCostQprice,
	@DeffdLcCostQprice,
	@DesignCostQprice,
	@StudioCostQprice,
	@OpertExpQprice,
	@CMCostQprice,
	@InterestQprice,
	@IncomeTaxQprice,
	@DepcAmortQprice,
	@CommissionQprice,
	@TotalCostQprice,
	@PriceDznQprice,
	@MarginDznQprice,
	@PricePcsQprice,
	@FinalCostPcsQprice,
	@MarginpcsQprice

 
 );
DEALLOCATE CUR_TEST
 
 
    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[TRIM]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TRIM](@string NVARCHAR(max))
    RETURNS NVARCHAR(max)
     BEGIN
      RETURN LTRIM(RTRIM(@string))
     END

GO
/****** Object:  UserDefinedFunction [dbo].[TrimsConsumtionTotalNAvgCaluculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create FUNCTION [dbo].[TrimsConsumtionTotalNAvgCaluculation](
 
	 
) RETURNS   @TrimSumNAvgCaltnTble TABLE(
	[TrimsCostId] [int]  NOT NULL,
	 
	[TotalCons] [float] NULL,
	[TotalEx] [float] NULL,
	[TotalTotCons] [float] NULL,
	[TotalRate] [float] NULL,
	[TotalAmount] [float] NULL,
	[TotalTotalQty] [float] NULL,
	[TotalTotalAmount] [float] NULL,

	[ConsAvg] [float] NULL,
	[ExAvg] [float] NULL,
	[TotConsAvg] [float] NULL,
	[RateAvg] [float] NULL,
	[AmountAvg] [float] NULL,
	[TotalQtyAvg] [float] NULL,
	[TotalAmountAvg] [float] NULL 
	 
	)
AS
BEGIN

Insert into @TrimSumNAvgCaltnTble Select TrimCostId,
 sum(Cons) as TotalCons,
sum(Ex) as TotalEx,
sum(TotCons) as TotalTotCons,
sum(Rate) as TotalRate,
sum(Amount) as TotalAmount,
sum(TotalQty) as TotalTotalQty ,
sum(TotalAmount) as TotalTotalAmount,

 avg(Cons) as ConsAvg,
avg(Ex) as ExAvg,
avg(TotCons) as TotConsAvg,
avg(Rate) as RateAvg,
avg(Amount) as AmountAvg,
avg(TotalQty) as TotalQtyAvg ,
avg(TotalAmount) as TotalAmountAvg   from ConsumptionEntryFormForTrimsCosts 
Group by TrimCostId

    RETURN ;
END;
GO
/****** Object:  UserDefinedFunction [dbo].[trimsCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from trimsCostPivotTbl()CREATE  FUNCTION [dbo].[trimsCostPivotTbl]( 	 )    RETURNS   @ATTTble TABLE(	[PrecostingId] [int]  NOT NULL	 	 ,[1]float null,[2]float null,[3]float null,[4]float null,[5]float null,[6]float null,[7]float null,[8]float null,[9]float null,[10]float null,[11]float null,[12]float null,[13]float null,[14]float null,[15]float null,[16]float null,[17]float null,[18]float null,[19]float null,[20]float null,[21]float null,[22]float null,[23]float null,[24]float null,[25]float null,[26]float null,[27]float null,[28]float null,[29]float null,[30]float null,[31]float null,[32]float null,[33]float null,[34]float null,[35]float null,[36]float null,[37]float null,[38]float null,[39]float null,[40]float null,[41]float null,[42]float null,[43]float null,[44]float null,[45]float null,[46]float null,[47]float null,[48]float null,[49]float null,[50]float null,[51]float null,[52]float null,[53]float null,[54]float null,[55]float null,[56]float null,[57]float null,[58]float null,[59]float null,[60]float null,[61]float null,[62]float null,[63]float null,[64]float null,[65]float null,[66]float null,[67]float null,[68]float null,[69]float null,[70]float null,[71]float null,[72]float null,[73]float null,[74]float null,[75]float null,[76]float null,[77]float null,[78]float null,[79]float null,[80]float null,[81]float null,[82]float null,[83]float null,[84]float null,[85]float null,[86]float null,[87]float null,[88]float null,[89]float null,[90]float null,[91]float null,[92]float null,[93]float null,[94]float null,[95]float null,[96]float null,[97]float null,[98]float null,[99]float null,[100]float null,[101]float null,[102]float null,[103]float null,[104]float null,[105]float null,[106]float null,[107]float null,[108]float null,[109]float null,[110]float null,[111]float null,[112]float null,[113]float null,[114]float null,[115]float null,[116]float null,[117]float null,[118]float null,[119]float null,[120]float null,[121]float null,[122]float null,[123]float null,[124]float null,[125]float null,[126]float null,[127]float null,[128]float null,[129]float null,[130]float null,[131]float null,[132]float null,[133]float null,[134]float null,[135]float null,[136]float null,[137]float null,[138]float null,[139]float null,[140]float null,[141]float null,[142]float null,[143]float null,[144]float null,[145]float null,[146]float null,[147]float null,[148]float null,[149]float null,[150]float null,[151]float null,[152]float null,[153]float null,[154]float null)ASBEGINinsert into @ATTTble  select PrecostingId,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],[37],[38],[39],[40],[41],[42],[43],[44],[45],[46],[47],[48],[49],[50],[51],[52],[53],[54],[55],[56],[57],[58],[59],[60],[61],[62],[63],[64],[65],[66],[67],[68],[69],[70],[71],[72],[73],[74],[75],[76],[77],[78],[79],[80],[81],[82],[83],[84],[85],[86],[87],[88],[89],[90],[91],[92],[93],[94],[95],[96],[97],[98],[99],[100],[101],[102],[103],[104],[105],[106],[107],[108],[109],[110],[111],[112],[113],[114],[115],[116],[117],[118],[119],[120],[121],[122],[123],[124],[125],[126],[127],[128],[129],[130],[131],[132],[133],[134],[135],[136],[137],[138],[139],[140],[141],[142],[143],[144],[145],[146],[147],[148],[149],[150],[151],[152],[153],[154] from  (select PrecostingId, GroupId,sum(TotalQty*Rate) as Tamount    from TrimCosts Where PrecostingId is not null group by PrecostingId,GroupId ) as sourcTbl   PIVOT(   Max(Tamount) for GroupId in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],[37],[38],[39],[40],[41],[42],[43],[44],[45],[46],[47],[48],[49],[50],[51],[52],[53],[54],[55],[56],[57],[58],[59],[60],[61],[62],[63],[64],[65],[66],[67],[68],[69],[70],[71],[72],[73],[74],[75],[76],[77],[78],[79],[80],[81],[82],[83],[84],[85],[86],[87],[88],[89],[90],[91],[92],[93],[94],[95],[96],[97],[98],[99],[100],[101],[102],[103],[104],[105],[106],[107],[108],[109],[110],[111],[112],[113],[114],[115],[116],[117],[118],[119],[120],[121],[122],[123],[124],[125],[126],[127],[128],[129],[130],[131],[132],[133],[134],[135],[136],[137],[138],[139],[140],[141],[142],[143],[144],[145],[146],[147],[148],[149],[150],[151],[152],[153],[154])   ) as Pivot_Tbl    RETURN ;END;--get item group name across the id (select * from ItemGroups)
GO
/****** Object:  UserDefinedFunction [dbo].[trimsCostPivotTblV2]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from trimsCostPivotTblV2()CREATE  FUNCTION [dbo].[trimsCostPivotTblV2]( 	 )    RETURNS   @ATTTble TABLE(	[PrecostingId] [int]  NOT NULL,	 	 Tamount float null)ASBEGINinsert into @ATTTble  select PrecostingId,Tamount from  (select PrecostingId,sum(TotalQty*Rate) as Tamount    from TrimCosts Where PrecostingId is not null group by PrecostingId ) as sourcTbl       RETURN ;END;--get item group name across the id (select * from ItemGroups)
GO
/****** Object:  UserDefinedFunction [dbo].[WashCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 --this is not working
 --select * from WashCostPivotTbl()
CREATE  FUNCTION [dbo].[WashCostPivotTbl](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL	 
	 ,[WashCost]float null)
AS
BEGIN
insert into @ATTTble  select PrecostingId,[WashCost] 
from
 ( select 
  wshCst.PrecostingId,
  wshCst.Name,
  sum(wshCst.Amount) TotalAmount 
   
 
 from WashCosts as wshCst
--left join Typpes as typ on wshCst.TypeId=typ.Id
--left join PreCostings as prcStng on prcStng.PrecostingId=wshCst.PrecostingId
group by  
  wshCst.PrecostingId,
  wshCst.Name ) as sourcTbl
   PIVOT(
   Max(TotalAmount) for Name in ([WashCost])
   ) as Pivot_Tbl

    RETURN ;
END;

 
GO
/****** Object:  UserDefinedFunction [dbo].[WashCostPivotTblv2]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 --select * from WashCostPivotTblv2()CREATE FUNCTION [dbo].[WashCostPivotTblv2]( 	 )    RETURNS   @ATTTble  TABLE(	[PrecostingId] [int]  NOT NULL	 	 ,[WashCost] nvarchar(max),	 [TotalAmount] float null)ASBEGINDECLARE          @PrecostingId int,		 @WashCost nvarchar(max),		 			 @tAmount float      DECLARE CUR_TEST CURSOR FAST_FORWARD FOR   select   wshCst.PrecostingId,  wshCst.Name,  sum(wshCst.Amount) TotalAmount      from WashCosts as wshCst where wshCst.PrecostingId is not null--left join Typpes as typ on wshCst.TypeId=typ.Id--left join PreCostings as prcStng on prcStng.PrecostingId=wshCst.PrecostingIdgroup by    wshCst.PrecostingId,  wshCst.Name                                                      OPEN CUR_TESTFETCH NEXT FROM CUR_TEST INTO @PrecostingId,@WashCost,@tAmount  WHILE @@FETCH_STATUS = 0BEGIN     set  @PrecostingId=@PrecostingId	if @WashCost='Wash' begin set	 @tAmount= @tAmount  end  Insert into @ATTTble VALUES (@PrecostingId,@WashCost,@tAmount);   FETCH NEXT FROM CUR_TEST INTO  @PrecostingId,@WashCost,@tAmount  ENDCLOSE CUR_TESTDEALLOCATE CUR_TEST      RETURN ;END; 
GO
/****** Object:  UserDefinedFunction [dbo].[YarnCostPivotTbl]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 --select * from YarnCostPivotTbl()
CREATE  FUNCTION [dbo].[YarnCostPivotTbl](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL	 
	 ,[1]float null,[2]float null,[3]float null,[4]float null,[5]float null,[6]float null,[7]float null,[8]float null,[9]float null,[10]float null,[11]float null,[12]float null,[13]float null,[14]float null,[15]float null,[16]float null,[17]float null,[18]float null,[19]float null,[20]float null,[21]float null,[22]float null,[23]float null,[24]float null,[25]float null)

AS
BEGIN
insert into @ATTTble  select PrecostingId,[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25]
from
 (select 
 prcCst.PrecostingId,
 YrnCst.CountId as CountId,
sum(YrnCst.Rate*dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty)) as TotalAmount

from YarnCosts as YrnCst
left join   PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId 
group by prcCst.PrecostingId,
 YrnCst.CountId) as sourcTbl
   PIVOT(
   Max(TotalAmount) for CountId in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],[25])
   ) as Pivot_Tbl

    RETURN ;
END;

--get item group name across the id (select * from YarnCounts)
GO
/****** Object:  UserDefinedFunction [dbo].[YarnCostWithLacra]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 --select * from YarnCostPivotTbl()
CREATE  FUNCTION [dbo].[YarnCostWithLacra](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL,
	   [TotalAmount] float null)

AS
BEGIN
insert into @ATTTble  select 
 prcCst.PrecostingId,
sum(YrnCst.Rate*dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty)) as TotalAmount

 from YarnCosts as YrnCst
left join   PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId 
where YrnCst.Comp1Id=1079
group by prcCst.PrecostingId 

    RETURN ;
END;

--get item group name across the id (select * from YarnCounts)
--select * from Compositions order by CompositionName
--select * from YarnCosts
GO
/****** Object:  UserDefinedFunction [dbo].[YarnCostWithOutLacra]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 --select * from YarnCostPivotTbl()
CREATE  FUNCTION [dbo].[YarnCostWithOutLacra](
 
	 
)
    RETURNS   @ATTTble TABLE(
	[PrecostingId] [int]  NOT NULL,
	   [TotalAmount] float null)

AS
BEGIN
insert into @ATTTble  select 
 prcCst.PrecostingId,
sum(YrnCst.Rate*dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty)) as TotalAmount

 from YarnCosts as YrnCst
left join   PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId 
where YrnCst.Comp1Id !=1079 
group by prcCst.PrecostingId 

    RETURN ;
END;

--get item group name across the id (select * from YarnCounts)
--select * from Compositions order by CompositionName
--select * from YarnCosts
GO
/****** Object:  UserDefinedFunction [dbo].[PiAndWorkOrderConnectivityFunction]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[PiAndWorkOrderConnectivityFunction]()
RETURNS TABLE
AS
RETURN (
with PiAndWorkOrderConnectivity as (select pro.Id as PiId,pro.ItemCategoryId,pro.PiNo,    case 	when pro.ItemCategoryId=95 then ypd.OrderAutoId    when pro.ItemCategoryId=3 then trmChild.OrderAutoId	when pro.ItemCategoryId=69 then embChld.OrderAutoId	when pro.ItemCategoryId=70 then embChld.OrderAutoId	when pro.ItemCategoryId=72 then embChld.OrderAutoId    else sbc.OrderAutoID end OrderId	 from ProFormaInvoiceV2PIDetails pro left join PiEntryFromWo piChild 			on piChild.PiMasterId=pro.Id
		left join YarnPurchaseOrderDetails ypd
		on ypd.Id=piChild.WorkOrderChildId
		left join YarnPurchaseOrders yp
       on yp.Id=ypd.YarnPurchaseOrderId
	   left join TrimsBookingItemDtlsChilds trmChild
	   on trmChild.Id=piChild.WorkOrderChildId
	   left join MultipleJobWiseTrimsBookingV2
      trimMaster on trimMaster.Id=trmChild.TrimsBookingMasterId
      left join EmbellishmentWODetailsChilds embChld
	  on embChld.Id=piChild.WorkOrderChildId
     left join MultipleJobWiseEmbellishmentWorkOrders emblMstr 
     on emblMstr.Id=embChld.EmbellishmentMasterId
     left join ServiceBookingAllChildDetails sbc 
	   on sbc.Id=piChild.WorkOrderChildId
        left JOIN ServiceBookingAllMasterDtls sbm  on sbm.Id=sbc.MasterId
)

select cnn.PiId,cnn.PiNo,p.PrecostingId,cnn.OrderId,cnn.ItemCategoryId,(SELECT LTRIM(RTRIM(p.Fileno)))Fileno,i.ItemCategoryName from PiAndWorkOrderConnectivity  cnn
    left join PreCostings p on p.OrderId=cnn.OrderId
	left join ItemCategories i on i.Id=cnn.ItemCategoryId
group by  cnn.PiId,cnn.PiNo,p.PrecostingId,cnn.OrderId,cnn.ItemCategoryId,p.Fileno,i.ItemCategoryName   
)

GO
/****** Object:  UserDefinedFunction [dbo].[BtbLcAndFileConnectivity]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE FUNCTION [dbo].[BtbLcAndFileConnectivity]
(

)
RETURNS TABLE
AS
RETURN
(
   with BTBORMargin as(				   select Id,value as PiMasterId from BTBORMarginLCs cross apply					string_split(PiMasterId,',') group by Id,PiMasterId,value),				  btbAndPiConnectivity as(				  select b.Id, b.PiMasterId,pi.PiNo,				(case when pi.PiBasis='Work Order Based' then fl.Fileno  else (SELECT LTRIM(RTRIM(pi.InternalFileNo)))end)FileNo				 from BTBORMargin b left join  ProFormaInvoiceV2PIDetails pi on pi.Id=b.PiMasterId				left join (select * from PiAndWorkOrderConnectivityFunction())fl on fl.PiId=b.PiMasterId)				--select * from BTBORMargin				select Id as BtbId,FileNo from btbAndPiConnectivity 				where FileNo is not null and FileNo <>'' 				group by Id,FileNo
)
GO
/****** Object:  UserDefinedFunction [dbo].[BnkRefExportInvoiceLcOrScConectivity]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[BnkRefExportInvoiceLcOrScConectivity]()
RETURNS TABLE
AS
RETURN
with BankRefOrBills as(
select Id,BankRefOrBillNo,value as ExportInvoiceIds from DocSubmissiontoBanks cross apply
string_split(ExportIds,',') group by Id,BankRefOrBillNo,value),   --Export invoice by each Bank Ref or Bill no 

 lcOrScByEachInvoice as ( select Id,InvoiceNo,UseLcOrSC,LcOrSCNo,value as LcOrScNumber   from ExportInvoiceUpdates cross apply
string_split(LcOrSCNo,',') group by Id,InvoiceNo,UseLcOrSC,value,LcOrSCNo)
select bnk.*,lcInv.InvoiceNo,lcInv.LcOrSCNo,lcInv.LcOrScNumber,lcInv.UseLcOrSC,
case when lcInv.UseLcOrSC='sc' then (SELECT TRIM(REPLACE( sc.InternalFileNo, ' ', '')))

     when  lcInv.UseLcOrSC='lc' then  (SELECT TRIM(REPLACE(lc.InternalFileNo, ' ', '')))
	 else null end InternalFileNo,
     sc.BankFileNo 
from BankRefOrBills bnk left join lcOrScByEachInvoice lcInv on lcInv.Id=bnk.ExportInvoiceIds
left join SalesContractEntries sc on sc.ContractNumber=lcInv.LcOrScNumber and lcInv.UseLcOrSC='sc'
left join ExportLCEntries  lc on lc.SystemID=lcInv.LcOrScNumber 
--and lcInv.UseLcOrSC='lc'
--select * from    ExportInvoiceUpdates 'MKL-LC-220002' 'MKL-LC-220002'
--select * from ExportProceedsRealizations

--select * from ExportLCEntries where  SystemID='MKL-LC-220000'--sc master
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessDocSubmissiontoBank]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
--select * from ProcessDocSubmissiontoBank()
CREATE function [dbo].[ProcessDocSubmissiontoBank]()
returns table 
as 
return 
(with BankRefOrBills as(
select Id,BankRefOrBillNo,value as ExportInvoiceIds from DocSubmissiontoBanks cross apply
string_split(ExportIds,',') group by Id,BankRefOrBillNo,value),   --Export invoice by each Bank Ref or Bill no 

 lcOrScByEachInvoice as ( select Id,InvoiceNo,UseLcOrSC,value as LcOrScNumber from ExportInvoiceUpdates cross apply
string_split(LcOrSCNo,',') group by Id,InvoiceNo,UseLcOrSC,value),  -- lc or sc numbers by each Invoice ,here is not present lc or sc id use lc or sc numbers

 BtbLcIdSc as( select LcOrScNumber,value as BtbIdSc from lcOrScByEachInvoice left join SalesContractEntries
 salesContract on salesContract.ContractNumber=lcOrScByEachInvoice.LcOrScNumber and
    lcOrScByEachInvoice.UseLcOrSC='sc'
 cross apply string_split(salesContract.ImportBTBId,',') group by LcOrScNumber,value
 ),
 BtbLcIdLc as( select LcOrScNumber,value as BtbIdLc from lcOrScByEachInvoice left join ExportLCEntries
 lc on lc.SystemID=lcOrScByEachInvoice.LcOrScNumber and
  lcOrScByEachInvoice.UseLcOrSC='lc'
 cross apply string_split(lc.ImportBTBId,',') 

 group by LcOrScNumber,value
 ),
 MergeBtbByBtbLcIdSc as (select BtbLcIdSc.LcOrScNumber,
                      STRING_AGG(btb.SystemID,',') as BtbLcNumbers,
                      STRING_AGG(btb.ProFormaInvoice,',') as ProFormaInvoices,
					  STRING_AGG(btb.Supplier,',') as Suppliers,
					  sum(btb.PIValue) PiValue,
					  sum(btb.LCValue) LCValue
                      from BtbLcIdSc left join BTBORMarginLCs btb 
                      on btb.Id=BtbLcIdSc.BtbIdSc group by BtbLcIdSc.LcOrScNumber
					  ),
 MergeBtbByBtbLcIdLc  as (select BtbLcIdLc.LcOrScNumber,
                      STRING_AGG(btb.SystemID,',') as BtbLcNumbers,
                      STRING_AGG(btb.ProFormaInvoice,',') as ProFormaInvoices,
					  STRING_AGG(btb.Supplier,',') as Suppliers,
					  sum(btb.PIValue) PiValue,
					  sum(btb.LCValue) LCValue
                      from BtbLcIdLc left join BTBORMarginLCs btb 
                      on btb.Id=BtbLcIdLc.BtbIdLc group by BtbLcIdLc.LcOrScNumber
					  )
                      ,
 ReadyInvoiceLevel as 
					(select Id as Id2,BankRefOrBillNo as BankRefOrBillNo2,
					STRING_AGG(InvoiceNo,',') InvoiceNo,
					sum(InvoiceValue) InvoiceValue,
					sum(NetInvoiceValue) NetInvoiceValue,
					STRING_AGG(UseLcOrSC,',') UseLcOrSC,
					STRING_AGG(LcOrScNumber,',') LcOrScNumber,
					sum(LcOrSCValue) LcOrSCValue,
					STRING_AGG(BtbLcNumbers,',') BtbLcNumbers,
					STRING_AGG(BtbProFormaInvoices,',') BtbProFormaInvoices,
					sum(BtbPiValue) BtbPiValue,
					sum(BtbLCValue) BtbLCValue 
					from (select BnkRf.*,lcOrSc.InvoiceNo,
									   subInv.InvoiceValue,subInv.NetInvoiceValue,lcOrSc.UseLcOrSC,
									   lcOrSc.LcOrScNumber,
								case when lcOrSc.UseLcOrSC='sc' then  salesContract.ContractValue
									 when lcOrSc.UseLcOrSC='lc' then lc.LcValue  
									 else 0 end LcOrSCValue,
								case when lcOrSc.UseLcOrSC='sc' then  m.BtbLcNumbers
									 when lcOrSc.UseLcOrSC='lc' then m2.BtbLcNumbers  
									 else null end BtbLcNumbers,
								case when lcOrSc.UseLcOrSC='sc' then  m.ProFormaInvoices
									 when lcOrSc.UseLcOrSC='lc' then m2.ProFormaInvoices  
									 else null end BtbProFormaInvoices
									 ,
								case when lcOrSc.UseLcOrSC='sc' then  m.Suppliers
									 when lcOrSc.UseLcOrSC='lc' then m2.Suppliers  
									 else null end BtbSuppliers 
									 ,
								case when lcOrSc.UseLcOrSC='sc' then  m.PiValue
									 when lcOrSc.UseLcOrSC='lc' then m2.PiValue  
									 else 0 end BtbPiValue,
								case when lcOrSc.UseLcOrSC='sc' then  m.LCValue
									 when lcOrSc.UseLcOrSC='lc' then m2.LCValue  
									 else 0 end BtbLCValue  
					from BankRefOrBills BnkRf left join lcOrScByEachInvoice lcOrSc
					on lcOrSc.Id=BnkRf.ExportInvoiceIds 
					left join MergeBtbByBtbLcIdSc m on  m.LcOrScNumber=lcOrSc.LcOrScNumber
					left join MergeBtbByBtbLcIdLc m2 on  m2.LcOrScNumber=lcOrSc.LcOrScNumber
					left join SalesContractEntries salesContract on salesContract.ContractNumber=lcOrSc.LcOrScNumber
					left join ExportLCEntries  lc on lc.SystemID=lcOrSc.LcOrScNumber
					 left join ExportInformationDetailsSubs subInv on subInv.ExportInvoiceId=BnkRf.ExportInvoiceIds
					) as tbl group by Id,BankRefOrBillNo 
					)
select invLvl.*,bnk.*,BuyerProfiles.ContactName as BuyerName,TblCompanyInfoes.Company_Name,BankInfoes.BankName
as SubmittedToName,ln.BankName as lienBankName,(case when Exists(select * from ExportProceedsRealizations where BillOrInvoiceId=invLvl.Id2) then 1 else 0 end)isRelizationDone
from ReadyInvoiceLevel invLvl 
left join   DocSubmissiontoBanks bnk on bnk.Id=invLvl.Id2
left join TblCompanyInfoes on bnk.CompanyNameID=TblCompanyInfoes.CompID
left join BuyerProfiles on bnk.BuyerId=BuyerProfiles.Id
left join BankInfoes on BankInfoes.Id=bnk.SubmittedTo
left join BankInfoes ln on ln.Id=bnk.LienBankId
)
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessEmbelCostForBkng]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
 CREATE FUNCTION [dbo].[ProcessEmbelCostForBkng](
    @JobNoId INT,@BuyerId int,@YearId int,@EmbelTypeId int
)
RETURNS TABLE
AS
RETURN 
with  
tbl1 as(select 
 BuyerName,
 BuyerId,
 StyleRef,
 JobName,
 OrderNo,
 PoDeptId,
 Id,
 PrecostingId,
 EmbelName,
 EmbelTypeId,
 BodyPartId,
 CountryId,
 SupplierId,
 sum(Cons) as Cons,
 avg(Rate) as Rate,
 sum(Amount) as Amount ,
 Status,              
 IsEmbellishmentCostBooking ,
 sum(ConsFromconsumption)as ConsFromconsumption,
 FileNo,
 InternalRef ,
 UomName,                
 GmtsItemName,
 EmbellTypeName,
 BodyPartEntry,
 OrderAutoId,
 embellishmentCostId ,
 CountryName,
 GmtsColor,
 Gmtssizes,
 EmbelCnsmtnId,
 RefNo,
 sum(ConsFromSizeQnty)as ConsFromSizeQnty  
 
 from (select 
BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
 '' as OrderNo,
 embelConsmption.PoId as PoDeptId,
 embel.Id,
 PrecostingId = embel.PrecostingId,
 embel.EmbelName,
 embel.EmbelTypeId,
 embel.BodyPartId,
 embel.CountryId,
 embel.SupplierId,
 (select dbo.EmbelishmentWorkOrederQnty(embel.Id))/12   as Cons,
  embel.Rate,
  embel.Amount,
  embel.Status,    
  (CASE WHEN EXISTS(SELECT 1 FROM EmbellishmentWODetailsChilds WITH(NOLOCK)
    WHERE EmbelCostId = embel.Id) THEN 1
    ELSE 0 END) AS IsEmbellishmentCostBooking,
 --(dbo.CheckIsConsumptionIdForEmblBkngExist(embelConsmption.Id)
	--) as IsEmbellishmentCostBooking ,
	--0 as IsEmbellishmentCostBooking ,
 (select dbo.EmbelishmentWorkOrederQnty(embel.Id))  as ConsFromconsumption,
    preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    UOMs.UomName,                
(select Items from GetItemNameInStringByOrderId(ord.OrderAutoID)) as GmtsItemName,
   EmbellishmentTypes.TypeName as EmbellTypeName,
   BodyPartEntries.BodyPartFullName as BodyPartEntry,
   ord.OrderAutoID as OrderAutoId,
   embel.Id as embellishmentCostId ,
   embelConsmption.Countries as CountryName,
   embelConsmption.GmtsColor,
   '' as Gmtssizes,
   0 as EmbelCnsmtnId,
   embelConsmption.RefNo,
  (case when embelConsmption.Cons>0 then embelConsmption.ConsFromSizeQnty else 0 end) as ConsFromSizeQnty
  
 
  from AddConsumptionFormForEmblishmentCosts embelConsmption 
  left join EmbellishmentCosts as embel  on embelConsmption.EmbelCostId=embel.Id
  left join PreCostings as preCst on embel.PreCostingId=preCst.PrecostingId
  left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
  left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
  left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
  left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
 left join UOMs on ord.Order_Uom_ID=UOMs.Id 
 left join TblRegionInfoes as country on embel.CountryId=country.RegionID

  where 
  preCst.PrecostingId is not null and 
  embelConsmption.Id is not null  
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
  AND @EmbelTypeId= CASE @EmbelTypeId WHEN 0 THEN 0 ELSE embel.EmbelTypeId END
  and preCst.OrderId=@JobNoId 
  and embel.ReportType='As per Gmts. Color' 
	 )as tbl
	group by 
	 BuyerName,
	 BuyerId,
	 StyleRef,
	 JobName,
	 OrderNo,
	 PoDeptId,
	 Id,
	 PrecostingId,
	 EmbelName,
	 EmbelTypeId,
	 BodyPartId,
	 CountryId,
	 SupplierId,
	 Status,              
	 IsEmbellishmentCostBooking,
	 FileNo,
	 InternalRef ,
	 UomName,                
	 GmtsItemName,
	 EmbellTypeName,
	 BodyPartEntry,
	 OrderAutoId,
	 embellishmentCostId ,
	 CountryName,
	 GmtsColor,
	 Gmtssizes,
	 EmbelCnsmtnId,
	 RefNo),
tbl2 as(select 
 BuyerName,
 BuyerId,
 StyleRef,
 JobName,
 OrderNo,
 PoDeptId,
 Id,
 PrecostingId,
 EmbelName,
 EmbelTypeId,
 BodyPartId,
 CountryId,
 SupplierId,
 sum(Cons) as Cons,
 avg(Rate) as Rate,
 sum(Amount) as Amount ,
 Status,              
 IsEmbellishmentCostBooking ,
 sum(ConsFromconsumption)as ConsFromconsumption,
 FileNo,
 InternalRef ,
 UomName,                
 GmtsItemName,
 EmbellTypeName,
 BodyPartEntry,
 OrderAutoId,
 embellishmentCostId ,
 CountryName,
 GmtsColor,
 Gmtssizes,
 EmbelCnsmtnId,
 RefNo,
 sum(ConsFromSizeQnty)as ConsFromSizeQnty  
 
 from (select 
BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
 '' as OrderNo,
embelConsmption.PoId as PoDeptId,
 embel.Id,
 PrecostingId = embel.PrecostingId,
 embel.EmbelName,
 embel.EmbelTypeId,
 embel.BodyPartId,
 embel.CountryId,
 embel.SupplierId,
 (select dbo.EmbelishmentWorkOrederQnty(embel.Id))/12   as Cons,
  embel.Rate,
  embel.Amount,
  embel.Status,              
 --(dbo.CheckIsConsumptionIdForEmblBkngExist(embelConsmption.Id)
	--) as IsEmbellishmentCostBooking ,
	(CASE WHEN EXISTS(SELECT 1 FROM EmbellishmentWODetailsChilds WITH(NOLOCK)
    WHERE EmbelCostId = embel.Id) THEN 1
    ELSE 0 END) AS IsEmbellishmentCostBooking,
 (select dbo.EmbelishmentWorkOrederQnty(embel.Id))  as ConsFromconsumption,
    preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    UOMs.UomName,                
(select Items from GetItemNameInStringByOrderId(ord.OrderAutoID)) as GmtsItemName,
   EmbellishmentTypes.TypeName as EmbellTypeName,
   BodyPartEntries.BodyPartFullName as BodyPartEntry,
   ord.OrderAutoID as OrderAutoId,
   embel.Id as embellishmentCostId ,
   embelConsmption.Countries as CountryName,
  '' as GmtsColor,
   embelConsmption.Gmtssizes,
   0 as EmbelCnsmtnId,
   embelConsmption.RefNo,
   (case when embelConsmption.Cons>0 then embelConsmption.ConsFromSizeQnty else 0 end) as ConsFromSizeQnty
  
 
  from AddConsumptionFormForEmblishmentCosts embelConsmption 
  left join EmbellishmentCosts as embel  on embelConsmption.EmbelCostId=embel.Id
  left join PreCostings as preCst on embel.PreCostingId=preCst.PrecostingId
  left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
  left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
  left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
  left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
 left join UOMs on ord.Order_Uom_ID=UOMs.Id 
 left join TblRegionInfoes as country on embel.CountryId=country.RegionID

  where 
  preCst.PrecostingId is not null and 
  embelConsmption.Id is not null
   AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
  AND @EmbelTypeId= CASE @EmbelTypeId WHEN 0 THEN 0 ELSE embel.EmbelTypeId END
  and preCst.OrderId=@JobNoId 
  and embel.ReportType='Size Sensitive' 
	 )as tbl
	group by 
	 BuyerName,
	 BuyerId,
	 StyleRef,
	 JobName,
	 OrderNo,
	 PoDeptId,
	 Id,
	 PrecostingId,
	 EmbelName,
	 EmbelTypeId,
	 BodyPartId,
	 CountryId,
	 SupplierId,
	 Status,              
	 IsEmbellishmentCostBooking,
	 FileNo,
	 InternalRef ,
	 UomName,                
	 GmtsItemName,
	 EmbellTypeName,
	 BodyPartEntry,
	 OrderAutoId,
	 embellishmentCostId ,
	 CountryName,
	 GmtsColor,
	 Gmtssizes,
	 EmbelCnsmtnId,
	 RefNo)
	(select *  from  tbl1) union (select *  from  tbl2)
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessInvoiceInfo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
create function [dbo].[ProcessInvoiceInfo]()
returns table 
as 
return 
(
 with cte as(
 select ExportInformationId,
 STRING_AGG (OrderNo, ',') as OrderNumbers,
 STRING_AGG (JobNo, ',') as JobNos,
 STRING_AGG (StyleRef, ',') as StyleRefs,
 sum(CurrInvoiceQnty) as CurrInvoiceQnty,
 sum(CurrInvoiceValue) as CurrInvoiceValue,
 max(ShipmentDate) as ShipmentDate
 from ExportInformationDetails group by ExportInformationId)
 select cte.*,inv.UseLcOrSC,inv.LcOrSCNo,inv.InvoiceDate,inv.ExpformNo,inv.LienBankId,
 subInv.InvoiceValue,subInv.NetInvoiceValue
 from  ExportInvoiceUpdates inv  left join cte on cte.ExportInformationId=inv.Id
        left join ExportInformationDetailsSubs subInv on subInv.ExportInvoiceId=inv.Id
)
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessTrimsCostForBkng]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

 CREATE FUNCTION [dbo].[ProcessTrimsCostForBkng](
    @JobNoId INT
)
RETURNS TABLE
AS
RETURN 
 with  
tbl1 as(
select   BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
'' as OrderNo,
 0 as PoDeptId,
 trimCost.Id,
  PrecostingId = trimCost.PrecostingId,
  trimCost.GroupId,
 trimCost.CountryId,
 cnsmptn.Countries as CountryName,
  trimCost.Description,
 trimCost.BrandSupRef,
   trimCost.Remarks,
  trimCost.NominatedSuppId,
  SupplierProfiles.SupplierName,
    trimCost.ConsUOMId,
   trimCost.ConsUnitGmts,
   avg(cnsmptn.Rate)as Rate,-- group Avg()
   avg(cnsmptn.Amount) as Amount,-- group Avg()
   sum(cnsmptn.TotalQty)  as TotalQty,-- group sum()
   sum(cnsmptn.TotalAmount)as  TotalAmount,-- group sum() 
    trimCost.ApvlReq,
     trimCost.ImagePath, 
	  0	as IsTrimBookingComplete,
 sum(cnsmptn.TotalQty) as ConsFromconsumption, 
 0 as Ex,
 0 as RateFromconsumption,
 preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    ItemGroups.ItemGroupName as  TrimsGroupName,
    UOMs.UomName,
    ord.OrderAutoID as OrderAutoId,
    trimCost.Id as TrimCostId,
	'' as Gmtssizes,
	0 as ConsumptionId,
    cnsmptn.GmtsColor,
    cnsmptn.RefNo,
	cnsmptn.GmtsItemId,
	trimCost.ReportType,
	'' as ItemColor,
	cnsmptn.PerAccessories,
	sum(cnsmptn.viewModelTotalQuantity) as SizeQnty,
	cnsmptn.mesurmentDescription

from ConsumptionEntryFormForTrimsCosts cnsmptn 
 left join TrimCosts as trimCost  on cnsmptn.TrimCostId=trimCost.Id
 left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
    left join ItemGroups on trimCost.GroupId=ItemGroups.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on trimCost.ConsUOMId=UOMs.Id
	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID
	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id
  --  left join TrimsConsumtionTotalNAvgCaluculation() as trimsTotalNAvgCltn
		-- on trimCost.Id=trimsTotalNAvgCltn.TrimsCostId 
	 
	  
  where 
  --trimCost.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
--and IsBookingComplete=0
   preCst.PrecostingId is not null
   and preCst.OrderId=@JobNoId
    and preCst.ApprovalStatus=2  
  and ReportType='As per Gmts. Color'
  
   and cnsmptn.Id is not null
   group by   
    BuyerProfiles.ContactName,ord.BuyerID,ord.Style_Ref,ord.JobNo,
	trimCost.Id,trimCost.PrecostingId,trimCost.GroupId,trimCost.CountryId,
	cnsmptn.Countries,trimCost.Description,trimCost.BrandSupRef,
	trimCost.Remarks,trimCost.NominatedSuppId,SupplierProfiles.SupplierName,
	trimCost.ConsUOMId,trimCost.ConsUnitGmts, trimCost.ApvlReq,
     trimCost.ImagePath, preCst.Fileno,
    preCst.internalRef,
    ItemGroups.ItemGroupName,
    UOMs.UomName,
    ord.OrderAutoID,
    trimCost.Id,
    cnsmptn.GmtsColor,
   cnsmptn.RefNo,
   cnsmptn.GmtsItemId,
	trimCost.ReportType,
	cnsmptn.PerAccessories,
	cnsmptn.mesurmentDescription),
	    
tbl2 as(select   BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
'' as OrderNo,
 0 as PoDeptId,
 trimCost.Id,
  PrecostingId = trimCost.PrecostingId,
  trimCost.GroupId,
 trimCost.CountryId,
 cnsmptn.Countries as CountryName,
  trimCost.Description,
 trimCost.BrandSupRef,
   trimCost.Remarks,
  trimCost.NominatedSuppId,
  SupplierProfiles.SupplierName,
    trimCost.ConsUOMId,
   trimCost.ConsUnitGmts,
   avg(cnsmptn.Rate)as Rate,-- group Avg()
   avg(cnsmptn.Amount) as Amount,-- group Avg()
   sum(cnsmptn.TotalQty)  as TotalQty,-- group sum()
   sum(cnsmptn.TotalAmount)as  TotalAmount,-- group sum() 
    trimCost.ApvlReq,
     trimCost.ImagePath, 
	  0	as IsTrimBookingComplete,
 sum(cnsmptn.TotalQty) as ConsFromconsumption, 
 0 as Ex,
 0 as RateFromconsumption,
 preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    ItemGroups.ItemGroupName as  TrimsGroupName,
    UOMs.UomName,
    ord.OrderAutoID as OrderAutoId,
    trimCost.Id as TrimCostId,
	cnsmptn.Gmtssizes as Gmtssizes,
	0 as ConsumptionId,
    '' as GmtsColor,
    cnsmptn.RefNo,
	cnsmptn.GmtsItemId,
	trimCost.ReportType,
	'' as ItemColor,
	cnsmptn.PerAccessories,
	sum(cnsmptn.viewModelTotalQuantity) as SizeQnty,
	cnsmptn.mesurmentDescription

from ConsumptionEntryFormForTrimsCosts cnsmptn 
 left join TrimCosts as trimCost  on cnsmptn.TrimCostId=trimCost.Id
 left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
    left join ItemGroups on trimCost.GroupId=ItemGroups.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on trimCost.ConsUOMId=UOMs.Id
	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID
	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id
  --  left join TrimsConsumtionTotalNAvgCaluculation() as trimsTotalNAvgCltn
		-- on trimCost.Id=trimsTotalNAvgCltn.TrimsCostId 
	 
	  
  where 
  --trimCost.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
--and IsBookingComplete=0
   preCst.PrecostingId is not null
  and preCst.OrderId=@JobNoId
   and preCst.ApprovalStatus=2 
   and ReportType='Size Sensitive'
  
   and cnsmptn.Id is not null
   group by   
    BuyerProfiles.ContactName,ord.BuyerID,ord.Style_Ref,ord.JobNo,
	trimCost.Id,trimCost.PrecostingId,trimCost.GroupId,trimCost.CountryId,
	cnsmptn.Countries,trimCost.Description,trimCost.BrandSupRef,
	trimCost.Remarks,trimCost.NominatedSuppId,SupplierProfiles.SupplierName,
	trimCost.ConsUOMId,trimCost.ConsUnitGmts, trimCost.ApvlReq,
     trimCost.ImagePath, preCst.Fileno,
    preCst.internalRef,
    ItemGroups.ItemGroupName,
    UOMs.UomName,
    ord.OrderAutoID,
    trimCost.Id,
   cnsmptn.Gmtssizes,
    cnsmptn.RefNo,
   cnsmptn.GmtsItemId,
	trimCost.ReportType,
	cnsmptn.PerAccessories,
	cnsmptn.mesurmentDescription),

	tbl3 as(select   BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
'' as OrderNo,
 0 as PoDeptId,
 trimCost.Id,
  PrecostingId = trimCost.PrecostingId,
  trimCost.GroupId,
 trimCost.CountryId,
 cnsmptn.Countries as CountryName,
  trimCost.Description,
 trimCost.BrandSupRef,
   trimCost.Remarks,
  trimCost.NominatedSuppId,
  SupplierProfiles.SupplierName,
    trimCost.ConsUOMId,
   trimCost.ConsUnitGmts,
   avg(cnsmptn.Rate)as Rate,-- group Avg()
   avg(cnsmptn.Amount) as Amount,-- group Avg()
   sum(cnsmptn.TotalQty)  as TotalQty,-- group sum()
   sum(cnsmptn.TotalAmount)as  TotalAmount,-- group sum() 
    trimCost.ApvlReq,
     trimCost.ImagePath, 
	  0	as IsTrimBookingComplete,
 sum(cnsmptn.TotalQty) as ConsFromconsumption, 
 0 as Ex,
 0 as RateFromconsumption,
 preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    ItemGroups.ItemGroupName as  TrimsGroupName,
    UOMs.UomName,
    ord.OrderAutoID as OrderAutoId,
    trimCost.Id as TrimCostId,
	cnsmptn.Gmtssizes as Gmtssizes,
	0 as ConsumptionId,
    cnsmptn.GmtsColor,
    cnsmptn.RefNo,
	cnsmptn.GmtsItemId,
	trimCost.ReportType,
	'' as ItemColor,
	cnsmptn.PerAccessories,
	sum(cnsmptn.viewModelTotalQuantity) as SizeQnty,
	cnsmptn.mesurmentDescription

from ConsumptionEntryFormForTrimsCosts cnsmptn 
 left join TrimCosts as trimCost  on cnsmptn.TrimCostId=trimCost.Id
 left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
    left join ItemGroups on trimCost.GroupId=ItemGroups.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on trimCost.ConsUOMId=UOMs.Id
	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID
	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id
   
	 
	  
  where 
   preCst.PrecostingId is not null
  -- and preCst.PrecostingId=10028
   and preCst.OrderId=@JobNoId
    and preCst.ApprovalStatus=2 
   and ReportType='Color & Size Sensitive'
    
   and cnsmptn.Id is not null
   group by   
    BuyerProfiles.ContactName,ord.BuyerID,ord.Style_Ref,ord.JobNo,
	trimCost.Id,trimCost.PrecostingId,trimCost.GroupId,trimCost.CountryId,
	cnsmptn.Countries,trimCost.Description,trimCost.BrandSupRef,
	trimCost.Remarks,trimCost.NominatedSuppId,SupplierProfiles.SupplierName,
	trimCost.ConsUOMId,trimCost.ConsUnitGmts, trimCost.ApvlReq,
     trimCost.ImagePath, preCst.Fileno,
    preCst.internalRef,
    ItemGroups.ItemGroupName,
    UOMs.UomName,
    ord.OrderAutoID,
    trimCost.Id,
   cnsmptn.Gmtssizes,
   cnsmptn.GmtsColor,
   cnsmptn.RefNo,
   cnsmptn.GmtsItemId,
	trimCost.ReportType,
	cnsmptn.PerAccessories,
	cnsmptn.mesurmentDescription), 


		tbl4 as(select   BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
'' as OrderNo,
 0 as PoDeptId,
 trimCost.Id,
  PrecostingId = trimCost.PrecostingId,
  trimCost.GroupId,
 trimCost.CountryId,
 cnsmptn.Countries as CountryName,
  trimCost.Description,
 trimCost.BrandSupRef,
   trimCost.Remarks,
  trimCost.NominatedSuppId,
  SupplierProfiles.SupplierName,
    trimCost.ConsUOMId,
   trimCost.ConsUnitGmts,
   avg(cnsmptn.Rate)as Rate,-- group Avg()
   avg(cnsmptn.Amount) as Amount,-- group Avg()
   sum(cnsmptn.TotalQty)  as TotalQty,-- group sum()
   sum(cnsmptn.TotalAmount)as  TotalAmount,-- group sum() 
    trimCost.ApvlReq,
     trimCost.ImagePath, 
	  0	as IsTrimBookingComplete,
 sum(cnsmptn.TotalQty) as ConsFromconsumption, 
 0 as Ex,
 0 as RateFromconsumption,
 preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    ItemGroups.ItemGroupName as  TrimsGroupName,
    UOMs.UomName,
    ord.OrderAutoID as OrderAutoId,
    trimCost.Id as TrimCostId,
	cnsmptn.Gmtssizes as Gmtssizes,
	0 as ConsumptionId,
    cnsmptn.GmtsColor,
    cnsmptn.RefNo,
	cnsmptn.GmtsItemId,
	trimCost.ReportType,
	cnsmptn.ItemColor,
	cnsmptn.PerAccessories,
	sum(cnsmptn.viewModelTotalQuantity) as SizeQnty,
	cnsmptn.mesurmentDescription

from ConsumptionEntryFormForTrimsCosts cnsmptn 
 left join TrimCosts as trimCost  on cnsmptn.TrimCostId=trimCost.Id
 left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
    left join ItemGroups on trimCost.GroupId=ItemGroups.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on trimCost.ConsUOMId=UOMs.Id
	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID
	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id
   
	 
	  
  where 
   preCst.PrecostingId is not null
  -- and preCst.PrecostingId=10028
   and preCst.OrderId=@JobNoId
    and preCst.ApprovalStatus=2 
   and ReportType='Contrast Color'
    
   and cnsmptn.Id is not null
   group by   
    BuyerProfiles.ContactName,ord.BuyerID,ord.Style_Ref,ord.JobNo,
	trimCost.Id,trimCost.PrecostingId,trimCost.GroupId,trimCost.CountryId,
	cnsmptn.Countries,trimCost.Description,trimCost.BrandSupRef,
	trimCost.Remarks,trimCost.NominatedSuppId,SupplierProfiles.SupplierName,
	trimCost.ConsUOMId,trimCost.ConsUnitGmts, trimCost.ApvlReq,
     trimCost.ImagePath, preCst.Fileno,
    preCst.internalRef,
    ItemGroups.ItemGroupName,
    UOMs.UomName,
    ord.OrderAutoID,
    trimCost.Id,
   cnsmptn.Gmtssizes,
   cnsmptn.GmtsColor,
   cnsmptn.RefNo,
   cnsmptn.GmtsItemId,
	trimCost.ReportType,
	cnsmptn.ItemColor,
	cnsmptn.PerAccessories,
	cnsmptn.mesurmentDescription)
(select *  from  tbl1) union (select *  from  tbl2) union
 (select *  from  tbl3) union (select * from tbl4)
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessYarnInfoByPrecostingIdAfterBkng]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from ProcessYarnInfoByPrecostingIdAfterBkng(0,2017,0) CREATE FUNCTION [dbo].[ProcessYarnInfoByPrecostingIdAfterBkng](   @OrderId int,@PrecostingId int,@PfbMasterId int )RETURNS TABLEASRETURN with cte  as  (select PreCostingId,FabricCostId,PartialFabricBookingMasterId,YarnId  from (select   pfbitemDtls.FabricCostId,   pfbitemDtls.PartialFabricBookingMasterId,   pfbitemDtls.PreCostingId,   YrnCst.Id as YarnId,pfbitemDtls.RefNo    from PartialFabricBookingItemDtlsChilds pfbitemDtls   left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostId   left join FabricCosts fabCst on fabCst.Id=YrnCst.FabricCostId   left join PreCostings pc on pc.PrecostingId=pfbitemDtls.PreCostingId   left join TblInitialOrders ord on ord.OrderAutoID=pc.OrderId --where pfbitemDtls.PreCostingId =2017    where  @PrecostingId= CASE @PrecostingId WHEN 0 THEN 0 ELSE pfbitemDtls.PreCostingId  END   AND @OrderId= CASE @OrderId WHEN 0 THEN 0 ELSE ord.OrderAutoID END  AND @PfbMasterId= CASE @PfbMasterId WHEN 0 THEN 0 ELSE pfbitemDtls.PartialFabricBookingMasterId END   ) pfb    group by PreCostingId,FabricCostId,PartialFabricBookingMasterId,YarnId   ),  ColorWiseSizeQuantity as (select OrderId=(select top(1) OrderId from Precostings where PrecostingId=@PrecostingId), Color,sum(Quanity) as Quantity From  SizePannelPodetails where PoId in(   select PoDetID From TblPodetailsInfroes where InitialOrderID=(select top(1) OrderId from Precostings where PrecostingId=@PrecostingId))   group by Color) --  ,     select JobNo,Style_Ref,PrecostingId,OrderAutoID,pfbMasterId,ProceessId,FabricCostId,RefNo, CountName,GmtsColor,ItemColor,percentage,sum(TotalCons) as Quantity,sum(ConsQnty) as ConsQnty,	Comp1Id,CountId,TypeId,avg(Rate) as Rate	from (	select  cte.PartialFabricBookingMasterId as pfbMasterId,TotalCons=(	case when (case when YrnCst.StripeClrId=0 then fcs.Color else strpClr.BodyColor end)=csq.Color then	 (csq.Quantity*YrnCst.ConsQnty)/12 else 0 end	 ),	  'Yarn Cost' as YarnCost,	 prcCst.PrecostingId,	 YrnCst.TypeId,	 tps.TypeName,	 yrnCunt.Name as CountName	,	 compstion.CompositionName,	 YrnCst.ConsQnty,	 YrnCst.percentage,  	  YrnCst.Rate,	   	  cte.FabricCostId as FabricCostId,	 '' as RefNo,	  --(case when YrnCst.StripeClrId=0 then fcs.Color else strpClr.BodyColor end) as GmtsColor,	 '' as GmtsColor,	 -- ( case when YrnCst.StripeClrId=0 then fcs.ContrastColor else strpClr.StripColor end) as ItemColor,	 '' as ItemColor,	  strpClr.Measurement,	  strpClr.FabricReqQty,	  YrnCst.CountId,	  YrnCst.Comp1Id,	  ord.OrderAutoID,	  ord.JobNo,	  ord.Style_Ref,	  ProceessId=21     from cte    left join  YarnCosts   as YrnCst on YrnCst.Id=cte.YarnId   left join  PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId    left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID   left join  Typpes as tps on tps.Id=YrnCst.TypeId   left join  YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id   left join  Compositions as compstion on YrnCst.Comp1Id=compstion.Id   left join  StripColors strpClr on strpClr.Id=YrnCst.StripeClrId   left join FabricColorSensitivities fcs on fcs.FabricId=cte.FabricCostId   left join ColorWiseSizeQuantity csq on csq.OrderId=ord.OrderAutoID     ) as tbl      group by JobNo,Style_Ref,PrecostingId,OrderAutoID,pfbMasterId,FabricCostId,RefNo,ProceessId,CountName,GmtsColor,ItemColor,   percentage,Comp1Id,CountId,TypeId
GO
/****** Object:  UserDefinedFunction [dbo].[ProcessYarnInfoByPrecostingIdAfterBkngWithFabric]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
    CREATE FUNCTION [dbo].[ProcessYarnInfoByPrecostingIdAfterBkngWithFabric](   @OrderId int,@PrecostingId int,@PfbMasterId int )RETURNS TABLEASRETURN  with cte  as  (select PreCostingId,FabricCostId,PartialFabricBookingMasterId,YarnId  from (select   pfbitemDtls.FabricCostId,   pfbitemDtls.PartialFabricBookingMasterId,   pfbitemDtls.PreCostingId,   YrnCst.Id as YarnId,pfbitemDtls.RefNo    from PartialFabricBookingItemDtlsChilds pfbitemDtls   left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostId   left join FabricCosts fabCst on fabCst.Id=YrnCst.FabricCostId   left join PreCostings pc on pc.PrecostingId=pfbitemDtls.PreCostingId   left join TblInitialOrders ord on ord.OrderAutoID=pc.OrderId --where pfbitemDtls.PreCostingId =2017    where  @PrecostingId= CASE @PrecostingId WHEN 0 THEN 0 ELSE pfbitemDtls.PreCostingId  END   AND @OrderId= CASE @OrderId WHEN 0 THEN 0 ELSE ord.OrderAutoID END  AND @PfbMasterId= CASE @PfbMasterId WHEN 0 THEN 0 ELSE pfbitemDtls.PartialFabricBookingMasterId END   ) pfb    group by PreCostingId,FabricCostId,PartialFabricBookingMasterId,YarnId   ),  ColorWiseSizeQuantity as (select OrderId=(select top(1) OrderId from Precostings where PrecostingId=@PrecostingId), Color,sum(Quanity) as Quantity From  SizePannelPodetails where PoId in(   select PoDetID From TblPodetailsInfroes where InitialOrderID=(select top(1) OrderId from Precostings where PrecostingId=@PrecostingId))   group by Color) --  ,     select JobNo,Style_Ref,PrecostingId,OrderAutoID,pfbMasterId,ProceessId,FabricCostId,RefNo, CountName,GmtsColor,ItemColor,percentage,sum(TotalCons) as Quantity,sum(ConsQnty) as ConsQnty,	Comp1Id,CountId,TypeId,avg(Rate) as Rate	from (	select  cte.PartialFabricBookingMasterId as pfbMasterId,TotalCons=(	case when (case when YrnCst.StripeClrId=0 then fcs.Color else strpClr.BodyColor end)=csq.Color then	 (csq.Quantity*YrnCst.ConsQnty)/12 else 0 end	 ),	  'Yarn Cost' as YarnCost,	 prcCst.PrecostingId,	 YrnCst.TypeId,	 tps.TypeName,	 yrnCunt.Name as CountName	,	 compstion.CompositionName,	 YrnCst.ConsQnty,	 YrnCst.percentage,  	  YrnCst.Rate,	   	  cte.FabricCostId as FabricCostId,	 '' as RefNo,	(case when YrnCst.StripeClrId=0 then fcs.Color else strpClr.BodyColor end) as GmtsColor,	 	( case when YrnCst.StripeClrId=0 then fcs.ContrastColor else strpClr.StripColor end) as ItemColor,	 	  strpClr.Measurement,	  strpClr.FabricReqQty,	  YrnCst.CountId,	  YrnCst.Comp1Id,	  ord.OrderAutoID,	  ord.JobNo,	  ord.Style_Ref,	  ProceessId=21     from cte    left join  YarnCosts   as YrnCst on YrnCst.Id=cte.YarnId   left join  PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId    left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID   left join  Typpes as tps on tps.Id=YrnCst.TypeId   left join  YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id   left join  Compositions as compstion on YrnCst.Comp1Id=compstion.Id   left join  StripColors strpClr on strpClr.Id=YrnCst.StripeClrId   left join FabricColorSensitivities fcs on fcs.FabricId=cte.FabricCostId   left join ColorWiseSizeQuantity csq on csq.OrderId=ord.OrderAutoID     ) as tbl      group by JobNo,Style_Ref,PrecostingId,OrderAutoID,pfbMasterId,FabricCostId,RefNo,ProceessId,CountName,GmtsColor,ItemColor,   percentage,Comp1Id,CountId,TypeId
GO
/****** Object:  StoredProcedure [dbo].[BankOrBilRefWithRealization]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   
 
CREATE PROCEDURE [dbo].[BankOrBilRefWithRealization]
AS
BEGIN
  with cte as (select rlz.*  --,bnk.InternalFileNo  select *from BnkRefExportInvoiceLcOrScConectivity() bnk where bnk.InternalFileNo in('www')  -- left join  from  ExportProceedsRealizations rlz --on rlz.BillOrInvoiceId=bnk.Id --where bnk.InternalFileNo in(@InternalFileNo) where rlz.Id is not null ),TotalDistributions as (select MasterId,sum(DocumentCurrency)as TotalDistribution   from ExportProceedsRealizationDistributions                       group by MasterId),TotalDeduction as (select MasterId,sum(DocumentCurrency)as TotalDeduction  from ExportProceedsRealizationDeductionsatSources                         group by MasterId) 	select cte.*,	--td.TotalDistribution,tdc.TotalDeduction,isnull(recieveAmount.Debit,0),isnull(transferAmount.Debit,0),	((isnull(td.TotalDistribution,0)+isnull(tdc.TotalDeduction,0)+isnull(recieveAmount.Credit,0))-isnull(transferAmount.Debit,0))TotalRealization,	isnull(tdc.TotalDeduction,0) as shortRealization,	'' as FileNo	from cte  left join TotalDistributions td on td.MasterId=cte.Id	  left join TotalDeduction tdc on tdc.MasterId=cte.Id	  left join (select BankRefId,sum(Debit)Debit from FCBRStatementEntry  f left join ParticularType p on p.Id=f.ParticularWHERE  p.ParticularValue NOT LIKE '%REC FROM FILE%' group by BankRefId) as transferAmount on transferAmount.BankRefId=cte.BillOrInvoiceIdleft join (select BankRefId,sum(Credit)Credit from FCBRStatementEntry  f left join ParticularType p on p.Id=f.ParticularWHERE p.ParticularValue  LIKE '%REC FROM FILE%' group by BankRefId) as recieveAmount on recieveAmount.BankRefId=cte.BillOrInvoiceIdend --select *from BnkRefExportInvoiceLcOrScConectivity() bnk where bnk.InternalFileNo in('www')
GO
/****** Object:  StoredProcedure [dbo].[BtbStatment]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 --exec BtbStatment '',1004
CREATE Procedure [dbo].[BtbStatment](@FileNo varchar(200),@InvoiceId int)asBeginwith cte as (select * from  ImportPayments),   paymentChild as (     select * from 	(	   select ImportPaymentMasterId,Replace(Replace(Replace(Rtrim(Ltrim(Replace(Replace(Replace(AdjSource,'/','')	   ,' ',''),'-',''))),'(',''),')',''),'.','')AdjSource,	   AcceptedAmount	  FROM ImportPaymentEntries	 )as PaymentchildPvot	 pivot	 (     sum(AcceptedAmount) for AdjSource in (										[BTBMarginDFCBLODADRADAC],										[ERQFCADAC],										[CDAccount],										[STDAC],										[CCAccount],										[ODAC],										[EDFAC],										[PAD],										[LTRMPI],										[FTTTR],										[LIM],										[TermLoan],										[ForceLoan],										[ImportMarginAC],										[DiscountAC],										[AdvanceAC],										[HPSM],										[SundryAC],										[MDASpecial],										[MDAUR] 										))as pivot_table),--create pivot tableacceptanceMaster as (select* from BTBOrImportLCInvoiceDetails),acceptanceChild as (               select pa.AcptnceMasterId,string_agg(pa.ItemCategory,',')ItemCategory,sum(CurrAcptncValue)CurrAcptncValue from( select AcptnceMasterId,ItemCategory,				sum(CurrAcptncValue)CurrAcptncValue 				from PiAcceptances                group by AcptnceMasterId,ItemCategory )as pa group by AcptnceMasterId ),BtbMerginLc as (select * from BTBORMarginLCs),--btb lc margin masterCommercialCommissionCostChild as (  select * from 	(	   select ccc.BtbId,Replace(Replace(Replace(Rtrim(Ltrim(Replace(Replace(Replace(sccc.CommissionName,'/','')	   ,' ',''),'-',''))),'(',''),')',''),'.','')AdjSource,	   ccc.Amount	  from CommersialCommissionCost ccc inner join      StaticValueOfCommersialCommissionCost sccc on sccc.Id=ccc.CommissionName	 )as PaymentchildPvot	 pivot	 (     sum(Amount) for AdjSource in  ([AcceptanceCommission],											[LCopeningCommission],											[AmendmentCommission],											[Swit],											[Charge],											[Stamp],											[InsuranceAndBankCharge]										))as pivot_table --create pivot table)select			cte.BankRefNo,			cmp.Company_Name as ImporterName,			sup.ContactPerson as SupplierName,			cte.BtbOrImportLCNo,			cte.InvoiceValue,            mg.LCDate,			mg.LCValue,			 ac.ItemCategory,			  ac.CurrAcptncValue Qty,			  a.LCNumber,			   mg.Tenor,			  a.InvoiceNumber,			  a.InvoiceDate,		--	cte.CurrencyId,			cte.ShipmentDate,			cte.BankAcceptanceDate,			--cte.BlOrCargoDate,			--cte.IssuingBankId,			--cte.MaturityFrom,			cte.MaturityDate,			cte.PaymentDate,			--cte.SystemNumber,			--cte.BankRefId,			--cte.BtbInvoiceId,	   isnull(acceptncAmnt.AcceptedAmount,0)AcceptedAmount, --p.ImportPaymentMasterId,isnull(p.BTBMarginDFCBLODADRADAC,0)BTBMarginDFCBLODADRADAC, isnull(p.ERQFCADAC,0)ERQFCADAC,isnull(p.CDAccount,0)CDAccount,isnull(p.STDAC,0)STDAC,isnull(p.CCAccount,0)CCAccount,isnull(p.ODAC,0)ODAC,isnull(p.EDFAC,0)EDFAC,isnull(p.PAD,0)PAD,isnull(p.LTRMPI,0)LTRMPI,isnull(p.FTTTR,0)FTTTR, isnull(p.LIM,0)LIM,isnull(p.TermLoan,0)TermLoan,isnull(p.ForceLoan,0)ForceLoan,isnull(p.ImportMarginAC,0)ImportMarginAC,isnull(p.DiscountAC,0)DiscountAC,isnull(p.AdvanceAC,0)AdvanceAC,isnull(p.HPSM,0)HPSM,isnull(p.SundryAC,0)SundryAC,isnull(p.MDASpecial,0)MDASpecial,isnull(p.MDAUR,0)MDAUR, --a.Id as acceptanceMasterId,-- a.IssuingBank, --a.DocumentValue,-- a.LCCurrency, --a.ShipmentDate,-- a.CompanyAccDate,a.SupplierId,a.BankAccDate,a.BankRef,a.Importer,-- a.AcceptanceTime,a.RetireSource,a.PayTerm,a.EDFTenor,a.Remarks,a.LCType,a.ExchangeRate, --ac.AcptnceMasterId,  --mg.Id MarginId,mg.PiMasterId,mg.SystemID,mg.Importer,mg.ApplicationDate,mg.IssuingBank,mg.ItemCategory, --mg.LCBasis,mg.ProFormaInvoice,mg.PIValue,mg.Supplier,mg.LCType,mg.LCNumberBankPart,mg.LCNumberCatPart,-- mg.LCNumberSerialPart,mg.LCDate,mg.LastShipmentDate,mg.LCExpiryDate,mg.LCValue,mg.IncoTerm,mg.IncoTermPlace, mg.PayTerm, --mg.TolerancePercentage,mg.DeliveryMode,mg.DocPresentDays,mg.PortofLoading,mg.PortofDischarge, --mg.ETDDate,mg.LCANo,mg.LCAFNo,mg.IMPFormNo,mg.InsuranceCompany,mg.CoverNoteNo,mg.CoverNoteDate,mg.PSICompany, mg.MaturityFrom,-- mg.MarginDepositPercentage,mg.Origin,mg.ShippingMark, mg.GarmentsQntyAndUOM,mg.UDNo,mg.UDDate, --mg.CreditToBeAdvised,mg.PartialShipment,mg.Transhipment,mg.AddConfirmationReq,mg.AddConfirmingBank,mg.BondedWarehouse,-- mg.UPASRatePercentage,mg.PivalueCurrency,mg.LCValueCurrency,mg.GarmentsQntyUOMValue, --ccc.BtbId, isnull(ccc.AcceptanceCommission,0)AcceptanceCommission, isnull(ccc.LCopeningCommission,0)LCopeningCommission, isnull(ccc.AmendmentCommission,0)AmendmentCommission, isnull(ccc.Swit,0)Swit, isnull(ccc.Charge,0)Charge, isnull(ccc.Stamp,0)Stamp, isnull(ccc.InsuranceAndBankCharge,0)InsuranceAndBankCharge, '' RelatedFileNo,BtbFile.FileNo,cte.BtbInvoiceId from cte left join paymentChild p on p.ImportPaymentMasterId=cte.Id               left join acceptanceMaster a on a.Id=cte.BtbInvoiceId			   left join acceptanceChild ac on ac.AcptnceMasterId=a.Id			   left join BtbMerginLc mg on mg.Id=a.BtbOrMarginLcMasterId			   left join CommercialCommissionCostChild ccc on ccc.BtbId=mg.Id			   left join SupplierProfiles sup on sup.Id=cte.SupplierId			   left join TblCompanyInfoes cmp on cmp.CompID=cte.ImporterId			   left join (select ImportPaymentMasterId,sum(AcceptedAmount)AcceptedAmount FROM ImportPaymentEntries group by ImportPaymentMasterId) as acceptncAmnt			   on acceptncAmnt.ImportPaymentMasterId=cte.Id 			   	   left join (					select * from BtbLcAndFileConnectivity()) BtbFile on btbFile.BtbId=mg.Id			   where 			    @FileNo= CASE @FileNo WHEN '' THEN '' ELSE BtbFile.FileNo END				AND  @InvoiceId= CASE @InvoiceId WHEN 0 THEN 0 ELSE cte.BtbInvoiceId END			  -- BtbFile.FileNo=@FileNo or			   --cte.BtbInvoiceId=@InvoiceIdEnd
GO
/****** Object:  StoredProcedure [dbo].[CollarNCuffRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[CollarNCuffRpt]
(
	@BookingId INT
	 
)
AS
BEGIN
 select cNc.*,pfb.RefNo,bp.BodyPartFullName from CollarNCuffs cNc left join PartialFabricBookingItemDtlsChilds pfb
 on cNc.ChildBkngId=pfb.Id left join BodyPartEntries bp on bp.Id=pfb.BodyPartId where pfb.PartialFabricBookingMasterId=@BookingId
END
GO
/****** Object:  StoredProcedure [dbo].[CollarRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  create PROC [dbo].[CollarRpt](	@BookingId INT	 )ASBEGIN select cNc.*,pfb.RefNo,bp.BodyPartFullName from CollarNCuffs cNc left join PartialFabricBookingItemDtlsChilds pfb on cNc.ChildBkngId=pfb.Id left join BodyPartEntries bp on bp.Id=pfb.BodyPartId where pfb.PartialFabricBookingMasterId=@BookingId and BodyPartFullName='Collar'END
GO
/****** Object:  StoredProcedure [dbo].[ColorAndSizeWiseBreakDownRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE PROC [dbo].[ColorAndSizeWiseBreakDownRpt](	@CmnCompanyId INT,	@StyleRef Varchar,	@JobNo Varchar,	@InitialOrderId int,	@Year INT,	@Month INT,	@ToDate Date,	@FromDate Date)ASBEGIN--DECLARE @stfWorker INT	--IF @StaffWorkBoth=1 SET @stfWorker=2	--IF @StaffWorkBoth=2 SET @stfWorker=1	--IF @StaffWorkBoth=3 SET @stfWorker=3	--IF @DepartmentId = 0 SET @DepartmentId = NULL 	--IF @EmployeeId = 0 SET @EmployeeId = NULL 	--IF @OfficeId = 0 SET @OfficeId = NULL	--IF @SecId IS NULL SET @SecId = 0	--IF @FloorId IS NULL SET @FloorId = 0	--IF @DegId IS NULL SET @DegId=0	 select ord.OrderAutoID,ord.JobNo,ord.CompanyID,ord.LocationID,ord.BuyerID,ord.Style_Ref,ord.Style_Description,ord.Prod_DeptID,ord.Sub_DeptID,ord.CurrencyID,ord.RegionID,ord.Product_CatID,ord.Team_Leader_ID,ord.Dealing_Merchant_ID,ord.BH_Merchant,ord.Remarks,ord.Shipment_Mode_ID,ord.Order_Uom_ID,ord.SMV,ord.Packing_ID, ord.Season_ID,ord.Agent_ID,ord.UserID,ord.Repeat_No_Job,ord.Order_Number,ord.OrderImagePath,ord.factory_merchant,ord.Status,ord.EntryDate,ord.EntryBy,   dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as PoQuantity, TblCompanyInfoes.Company_Name, TblLocationInfoes.Location_Name, BuyerProfiles.ContactName, TblProductionDeptInfoes.ProdDeptName , ProductSubDepartments.SubDepartmentName, DiscountMethods.DiscountMethodName, TblRegionInfoes.Region_Name, ProductCategories.ProductCategoryName, userInfTmldr.FullName as TeamLeaderName, userDlngMrcnd.FullName as dealingMarchandName, TblShipmentModeInfoes.Shipment_Mode, UOMs.UomName, TblSeasonInfoes.Season_Name,TblAgentInfoes.Agent_Name,uInf.FullName UserName ,userFctryMrcnd.FullName as FactoryMarchandName,--itmDtls.id as itemDtlsId,itmDtls.item,itmDtls.ratio,itmDtls.sew_smv_pcs,GarmentsItemEntries.ItemName,poDtls.PoDetID,poDtls.POOrderStatusID,poDtls.PO_No,poDtls.PO_Received_Date,poDtls.Pub_Shipment_Date,poDtls.Org_Shipment_Date,poDtls.Fac_Receive_Date,poDtls.PO_Quantity,poDtls.Avg_Price,poDtls.Amount as PoAmount,poDtls.Excess_Cut,poDtls.Plan_Cut,poDtls.PoStatusID,poDtls.Projected_Po,poDtls.TNA_FromOrUpto ,inptPnnl.Input_Pannel_ID,inptPnnl.CountryID,inptPnnl.Country_Type,inptPnnl.Cutt_off_Date,inptPnnl.Cutt_off,inptPnnl.Country_Shipment_date,inptPnnl.Remarks as countryRemarks,inptPnnl.Quantity as cntryQuantity ,cntry.Region_Name as CountryName,szeWiseBrkdwn.SizePannelId,szeWiseBrkdwn.Status as sizeStatus,szeWiseBrkdwn.ItemId,szeWiseBrkdwn.ArticleNumber,szeWiseBrkdwn.Color,szeWiseBrkdwn.Size,szeWiseBrkdwn.Quanity as sizeQnty,szeWiseBrkdwn.Rate as sizeRate,szeWiseBrkdwn.PlanCutQty ,szeWiseBrkdwn.ExcessCut ,szeWiseBrkdwn. Amount as sizeAmount,szeWiseBrkdwn.BarCode ,sizeItemEntries.ItemName as sizeItemName,--szeWiseBrkdwn.ArticleNumberdbo.ColorAndSizeWiseBreakDownTableLeangthRpt(ord.OrderAutoID) as tblLenght from TblInitialOrders as ord left join  TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID --left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID  left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID left join TblCompanyInfoes on ord.CompanyID=TblCompanyInfoes.CompID left join TblLocationInfoes on ord.LocationID=TblLocationInfoes.LocationId left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id left join  TblProductionDeptInfoes on ord.Prod_DeptID=TblProductionDeptInfoes.ID left join   ProductSubDepartments on ord.Sub_DeptID=ProductSubDepartments.Id left join  DiscountMethods on ord.CurrencyID=DiscountMethods.Id left join TblRegionInfoes on ord.RegionID=TblRegionInfoes.RegionID left join ProductCategories on ord.Product_CatID=ProductCategories.Id-- left join TblUserInfoes as userInf on ord.Team_Leader_ID=userInf.UserID --left join TblUserInfoes on ord.Dealing_Merchant_ID=TblUserInfoes.UserID left join TblShipmentModeInfoes on ord.Shipment_Mode_ID=TblShipmentModeInfoes.ID left join UOMs on ord.Order_Uom_ID=UOMs.Id --write packing here first create table left join TblSeasonInfoes on ord.Season_ID=TblSeasonInfoes.SeasonID left join TblAgentInfoes on ord.Agent_ID=TblAgentInfoes.AgentID left join TblUserInfoes as uInf on ord.UserID=uInf.UserID --left join TblUserInfoes as fmUInf on ord.factory_merchant=fmUInf.UserID left join GarmentsItemEntries on szeWiseBrkdwn.ItemId=GarmentsItemEntries.Id --write PoOrderStatus here first create table PoOrderStatus left join TblRegionInfoes as cntry on inptPnnl.CountryID =cntry.RegionID left join GarmentsItemEntries as sizeItemEntries on szeWiseBrkdwn.ItemId=sizeItemEntries.Id left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID) left join TblUserInfoes as userInfTmldr on userInfTmldr.UserId=(select top(1) UserId  from UserMappings where Id=ord.Team_Leader_ID)  left join TblUserInfoes as userFctryMrcnd on userFctryMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.factory_merchant) --where ord.CompanyID=  where ord.OrderAutoID=@InitialOrderId and szeWiseBrkdwn.SizePannelId is not null order by szeWiseBrkdwn.SizePannelId    --order by ord.OrderAutoID,poDtls.PoDetID,cntry.RegionID,szeWiseBrkdwn.ItemId  END
GO
/****** Object:  StoredProcedure [dbo].[ColorAndSizeWiseBreakDownRptV2]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
create PROC [dbo].[ColorAndSizeWiseBreakDownRptV2]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
 select JobNo,
sum(case when Size='S'  then sizeQnty else 0 end) as S,
sum(case when Size='M'  then sizeQnty else 0 end) as M,
sum(case when Size='L'  then sizeQnty else 0 end) as L,
sum(case when Size='XL'  then sizeQnty else 0 end) as XL,
sum(case when Size='XXL'  then sizeQnty else 0 end) as XXL  from (select 
ord.OrderAutoID,ord.JobNo,ord.CompanyID,ord.LocationID,
ord.BuyerID,ord.Style_Ref,ord.Style_Description,ord.Prod_DeptID,ord.Sub_DeptID,
ord.CurrencyID,ord.RegionID,ord.Product_CatID,ord.Team_Leader_ID,ord.Dealing_Merchant_ID,
ord.BH_Merchant,ord.Remarks,ord.Shipment_Mode_ID,ord.Order_Uom_ID,ord.SMV,ord.Packing_ID, 
ord.Season_ID,ord.Agent_ID,ord.UserID,ord.Repeat_No_Job,ord.Order_Number,ord.OrderImagePath,ord.factory_merchant,
ord.Status,ord.EntryDate,ord.EntryBy, 

  dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as PoQuantity,

 TblCompanyInfoes.Company_Name,
 TblLocationInfoes.Location_Name,
 BuyerProfiles.ContactName,
 TblProductionDeptInfoes.ProdDeptName ,
 ProductSubDepartments.SubDepartmentName,
 DiscountMethods.DiscountMethodName,
 TblRegionInfoes.Region_Name,
 ProductCategories.ProductCategoryName,
 userInfTmldr.FullName as TeamLeaderName,
 userDlngMrcnd.FullName as dealingMarchandName,
 TblShipmentModeInfoes.Shipment_Mode,
 UOMs.UomName,
 TblSeasonInfoes.Season_Name,
TblAgentInfoes.Agent_Name,
uInf.FullName UserName ,
userFctryMrcnd.FullName as FactoryMarchandName,


--itmDtls.id as itemDtlsId,itmDtls.item,itmDtls.ratio,itmDtls.sew_smv_pcs,
GarmentsItemEntries.ItemName,


poDtls.PoDetID,poDtls.POOrderStatusID,poDtls.PO_No,
poDtls.PO_Received_Date,poDtls.Pub_Shipment_Date,poDtls.Org_Shipment_Date,
poDtls.Fac_Receive_Date,
poDtls.PO_Quantity,poDtls.Avg_Price,poDtls.Amount as PoAmount,
poDtls.Excess_Cut,poDtls.Plan_Cut,poDtls.PoStatusID,poDtls.Projected_Po,
poDtls.TNA_FromOrUpto ,

inptPnnl.Input_Pannel_ID,inptPnnl.CountryID,inptPnnl.Country_Type,
inptPnnl.Cutt_off_Date,
inptPnnl.Cutt_off,
inptPnnl.Country_Shipment_date,inptPnnl.Remarks as countryRemarks,
inptPnnl.Quantity as cntryQuantity ,
cntry.Region_Name as CountryName,

szeWiseBrkdwn.SizePannelId,szeWiseBrkdwn.Status as sizeStatus,
szeWiseBrkdwn.ItemId,szeWiseBrkdwn.ArticleNumber,
szeWiseBrkdwn.Color,szeWiseBrkdwn.Size,
szeWiseBrkdwn.Quanity as sizeQnty,szeWiseBrkdwn.Rate as sizeRate,
szeWiseBrkdwn.PlanCutQty ,szeWiseBrkdwn.ExcessCut ,
szeWiseBrkdwn. Amount as sizeAmount,szeWiseBrkdwn.BarCode ,
sizeItemEntries.ItemName as sizeItemName
--szeWiseBrkdwn.ArticleNumber


 from TblInitialOrders as ord left join 
 TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 --left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id
 left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID 
 left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID

 left join TblCompanyInfoes on ord.CompanyID=TblCompanyInfoes.CompID
 left join TblLocationInfoes on ord.LocationID=TblLocationInfoes.LocationId
 left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
 left join  TblProductionDeptInfoes on ord.Prod_DeptID=TblProductionDeptInfoes.ID
 left join   ProductSubDepartments on ord.Sub_DeptID=ProductSubDepartments.Id
 left join  DiscountMethods on ord.CurrencyID=DiscountMethods.Id
 left join TblRegionInfoes on ord.RegionID=TblRegionInfoes.RegionID
 left join ProductCategories on ord.Product_CatID=ProductCategories.Id
-- left join TblUserInfoes as userInf on ord.Team_Leader_ID=userInf.UserID
 --left join TblUserInfoes on ord.Dealing_Merchant_ID=TblUserInfoes.UserID
 left join TblShipmentModeInfoes on ord.Shipment_Mode_ID=TblShipmentModeInfoes.ID
 left join UOMs on ord.Order_Uom_ID=UOMs.Id
 --write packing here first create table
 left join TblSeasonInfoes on ord.Season_ID=TblSeasonInfoes.SeasonID
 left join TblAgentInfoes on ord.Agent_ID=TblAgentInfoes.AgentID
 left join TblUserInfoes as uInf on ord.UserID=uInf.UserID
 --left join TblUserInfoes as fmUInf on ord.factory_merchant=fmUInf.UserID
 left join GarmentsItemEntries on szeWiseBrkdwn.ItemId=GarmentsItemEntries.Id
 --write PoOrderStatus here first create table PoOrderStatus
 left join TblRegionInfoes as cntry on inptPnnl.CountryID =cntry.RegionID
 left join GarmentsItemEntries as sizeItemEntries on szeWiseBrkdwn.ItemId=sizeItemEntries.Id

 left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
 left join TblUserInfoes as userInfTmldr on userInfTmldr.UserId=(select top(1) UserId  from UserMappings where Id=ord.Team_Leader_ID)
  left join TblUserInfoes as userFctryMrcnd on userFctryMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.factory_merchant)
 --where ord.CompanyID=
 
 where ord.OrderAutoID=3011 
) as tbl group by JobNo,Size	

  
END
GO
/****** Object:  StoredProcedure [dbo].[CommercialCostRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CommercialCostRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
  CmrclCst.Id,
   CmrclCst.Item,
    CmrclCst.RateIn,
	 CmrclCst.Amount,
	(CmrclCst.Amount/12*dbo.GetPoQuantityByOrderId(prcStng.OrderId)) as TotalAmount,
    CmrclCst.Status
from CommercialCosts  as CmrclCst
left join PreCostings as prcStng on prcStng.PrecostingId=CmrclCst.PrecostingId 
where prcStng.OrderId=@InitialOrderId
END
--select * from CommercialCosts
GO
/****** Object:  StoredProcedure [dbo].[CommissionCostRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CommissionCostRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
  cmsCost.Id,
   cmsCost.Amount ,
    cmsCost.CommnBase,
	 cmsCost.CommnRate,
    cmsCost.Status,
	cmsCost.Particulars,
	(cmsCost.Amount/12*dbo.GetPoQuantityByOrderId(prcStng.OrderId)) as TotalAmount
 from CommissionCosts  as cmsCost
left join PreCostings as prcStng on prcStng.PrecostingId=cmsCost.PrecostingId  

where prcStng.OrderId=@InitialOrderId
END
GO
/****** Object:  StoredProcedure [dbo].[ConversionCostRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 CREATE PROC [dbo].[ConversionCostRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId  int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
 prductnPrces.Id,
 prductnPrces.ProductionProcessName,
 (CnversnCst.ChargeUnit*CnversnCst.AvgReqQty) as Amount,
 CnversnCst.AvgReqQty,
 CnversnCst.ChargeUnit,
 CnversnCst.ProcessLoss,
 fabCost.ConsumptionBasis,
 fabCost.Uom,
 fabCost.AvgGreyCons as  ConsByDzn,
 -- dbo.PrecstingtTotalConsCalculation(fabCost.AvgGreyCons,prcStng.jobQty) as TotalCons,
 cast(Cnsmtn.TotalCons AS  DECIMAL(18,4)) AS TotalCons,
  (cast(Cnsmtn.TotalCons AS  DECIMAL(18,4))*CnversnCst.ChargeUnit) as TotalAmount,
  --fabCost.FabricDescription 
 bdPart.BodyPartFullName+','+ColorTypes.ColorTypeName+','+fabCost.FabricDescription as Particulars
 
from ConversionCostForPreCosts as CnversnCst
left join PreCostings as prcStng on prcStng.PrecostingId=CnversnCst.PrecostingId  
left join fabricCosts as fabCost on fabcost.Id=CnversnCst.FabricCostId
left join BodyPartEntries as bdPart on bdPart.Id=fabcost.BodyPartId
left join ColorTypes  on fabCost.ColorTypeId=ColorTypes.Id
left join ProductionProcesses as prductnPrces on CnversnCst.ProcessId=prductnPrces.Id
left join (select FabricCostId,sum((SizeQuantity/12)* GreyCons) TotalCons from ConsumptionEntryForms where FinishCons>0 
group by FabricCostId) Cnsmtn on Cnsmtn.FabricCostId=CnversnCst.FabricCostId	
 where prcStng.OrderId=@InitialOrderId order by ProductionProcessName
END
GO
/****** Object:  StoredProcedure [dbo].[CuffRibRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  create PROC [dbo].[CuffRibRpt](	@BookingId INT	 )ASBEGIN select cNc.*,pfb.RefNo,bp.BodyPartFullName from CollarNCuffs cNc left join PartialFabricBookingItemDtlsChilds pfb on cNc.ChildBkngId=pfb.Id left join BodyPartEntries bp on bp.Id=pfb.BodyPartId where pfb.PartialFabricBookingMasterId=@BookingId and BodyPartFullName='Cuff Rib'END 
GO
/****** Object:  StoredProcedure [dbo].[CuffRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  create PROC [dbo].[CuffRpt](	@BookingId INT	 )ASBEGIN select cNc.*,pfb.RefNo,bp.BodyPartFullName from CollarNCuffs cNc left join PartialFabricBookingItemDtlsChilds pfb on cNc.ChildBkngId=pfb.Id left join BodyPartEntries bp on bp.Id=pfb.BodyPartId where pfb.PartialFabricBookingMasterId=@BookingId and BodyPartFullName='Cuff'END
GO
/****** Object:  StoredProcedure [dbo].[DeleteAllOfferingCost]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[DeleteAllOfferingCost]
(
	@OfferingCostId INT 
	 
)
AS
BEGIN
 delete  from OfferingCostCostingSheets where Id=@OfferingCostId;
 delete  from OfferingCostBuyerInformations where OfferingCostId=@OfferingCostId;
delete  from OfferingCostConsumptionCosts where OfferingCostId=@OfferingCostId;
delete  from OfferingCostFabricInformations where OfferingCostId=@OfferingCostId;
delete   from OfferingCostInformations  where OfferingCostId=@OfferingCostId;
 
END
GO
/****** Object:  StoredProcedure [dbo].[DeleteEmbellishmentWODetailsChild]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[DeleteEmbellishmentWODetailsChild](	@Id INT 	 )ASBEGIN delete  from EmbellishmentWODetailsChilds where Id=@Id;   END
GO
/****** Object:  StoredProcedure [dbo].[DeleteFromOrderByOrderAutoId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE  proc [dbo].[DeleteFromOrderByOrderAutoId]
	@OrderId int
AS
BEGIN
 DECLARE @PrecostingId INT
--Declare  @OrderId int=12039
set @OrderId=12039
 select @PrecostingId=PrecostingId from PreCostings where OrderId=@OrderId
 
Delete From TblInitialOrders where OrderAutoID=@OrderId
Delete From  ItemDetailsOrderEntries where  order_entry_id=@OrderId
Delete From TblPodetailsInfroes where InitialOrderID=@OrderId
Delete From InputPannelPodetails where  Po_details_ID in(select PoDetID From TblPodetailsInfroes where InitialOrderID=@OrderId)
Delete From  SizePannelPodetails where PoId in(select PoDetID From TblPodetailsInfroes where InitialOrderID=@OrderId)




Delete From  PreCostings where PrecostingId=@PrecostingId
Delete From  CostComponenetsMasterDetails where PreCostingId=@PrecostingId
Delete From  FabricCosts where PreCostingId=@PrecostingId
Delete From  YarnCosts where precostingId=@PrecostingId

Delete From  ConversionCostChargeOrUnits where Id in 
(select Id from ConversionCostForPreCosts where PrecostingId=@PrecostingId)
Delete From  ConversionCostForPreCosts where PrecostingId=@PrecostingId

Delete From  TrimCosts where PrecostingId=@PrecostingId
Delete From  EmbellishmentCosts where PrecostingId=@PrecostingId
Delete From  WashCosts where PrecostingId=@PrecostingId
Delete From  CommercialCosts where PrecostingId=@PrecostingId
Delete From  CommissionCosts where PrecostingId=@PrecostingId

Delete from YarnConsOptimaizationStripeColor where StripeColorId in 
(Select Id From  StripColors where PrecostingId=@PrecostingId)
Delete From  StripColors where PrecostingId=@PrecostingId
Delete from FabricColorSensitivities where PrecostingId=@PrecostingId
--consumption
Delete From  ConsumptionEntryForms where PrecostingId=@PrecostingId
Delete From  ConsumptionEntryFormForTrimsCosts where PrecostingId=@PrecostingId

Delete From  AddConsumptionFormForEmblishmentCosts where PrecostingId=@PrecostingId

Delete From  AddConsumptionFormForGmtWashCosts where PrecostingId=@PrecostingId


--booking
--Delete From  PartialFabricBookings  where PreCostingId=@PrecostingId
Delete From  PartialFabricBookingItemDtlsChilds where PreCostingId=@PrecostingId

Delete From  MultipleJobWiseTrimsBookingV2
Delete From  TrimsBookingItemDtlsChilds where PreCostingId=@PrecostingId

--Delete From  MultipleJobWiseEmbellishmentWorkOrders  where Order=@PrecostingId
Delete From  EmbellishmentWODetailsChilds where OrderAutoId=@OrderId

Delete From  YarnPurchaseOrders
Delete From  YarnPurchaseOrderDetails  where OrderAutoId=@OrderId
 
Delete From  ServiceBookingAllMasterDtls
Delete From  ServiceBookingAllChildDetails where PrecostingId=@PrecostingId
END



GO
/****** Object:  StoredProcedure [dbo].[DeletePartialFabricBookingItemDtlsChilds]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 create PROC [dbo].[DeletePartialFabricBookingItemDtlsChilds](	@Id INT 	 )ASBEGIN delete  from PartialFabricBookingItemDtlsChilds where Id=@Id;   END
GO
/****** Object:  StoredProcedure [dbo].[DeleteTrimsBookingItemDtlsChild]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 create PROC [dbo].[DeleteTrimsBookingItemDtlsChild](	@Id INT 	 )ASBEGIN delete  from TrimsBookingItemDtlsChilds where Id=@Id;   END
GO
/****** Object:  StoredProcedure [dbo].[DeleteYarnCostByFabricIdNStripeRefrnc]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  proc [dbo].[DeleteYarnCostByFabricIdNStripeRefrnc]
	@FabricId int
AS
BEGIN
  Delete  from YarnCosts where FabricCostId=@FabricId and isLoadFromStripeClr=1
   
END
GO
/****** Object:  StoredProcedure [dbo].[EmbelishmentBookingJobWiseRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE PROC [dbo].[EmbelishmentBookingJobWiseRpt](@BookingId Int,	@BuyerId Int,	@jobNoId Int,	@poNoId Int,	@styleRef varchar,	@YearId Int 	 )ASBEGIN   select  ord.JobNo, ord.Style_Ref, ord.Repeat_No_Job,  BuyerWiesSeasons.SeasonName, BuyerProfiles.ContactName, embel.Id, embel.Level, embel.WoNo as BookingNo, embel.WODate as BookingDate, embel.DeliveryDate, dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as PoQnty, currency.DiscountMethodName as currencyName, userDlngMrcnd.FullName as DealingMarchand, embel.PayMode,  embel.Remarks,   embel.Source,    embel.Attention,  embelChild.EmbelCostId,  embelChild.Woq,  embelChild.Rate,  (embelChild.Rate*(embelChild.CnsFromSizeQnty)) as Amount, SupplierProfiles.SupplierName, embelChild.EmbName, embelChild.BodyPart, embelChild.EmbType , -- embeCnsmtion.PoNo, poDtls.PO_No as PoNo,   embelChild.GarmentesItem, embelChild.GarmentesItem as ItemName, embelChild.GmtsColor,embelChild.Gmtssizes,--(case when embeCnsmtion.Cons>0 then embeCnsmtion.ConsFromSizeQnty else 0 end) as ConsFromSizeQnty,embelChild.CnsFromSizeQnty,-- fabCst.Id as FabricCostId, preCst.PrecostingId ,(select top(1) BookingQnty from  getEmblBookingQnty(embel.Id)) as BookingQnty, --dbo.GetColorSensitivityByFabricId(fabCst.Id) as ContrastColor --clrSensitive.ContrastColor --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id) embelChild.RefNo   from MultipleJobWiseEmbellishmentWorkOrders as embel  left join  EmbellishmentWODetailsChilds embelChild on embelChild.EmbellishmentMasterId= embel.Id  --left join  EmbellishmentCosts as embelCost on embelChild.EmbelCostId=embelCost.Id left join  TblInitialOrders as ord  on ord.OrderAutoID=embelChild.OrderAutoId left join PreCostings as preCst on preCst.OrderId=ord.OrderAutoID left join  TblPodetailsInfroes  poDtls on poDtls.PoDetID=embelChild.PoDeptId left join SupplierProfiles on embel.SupplierNameId=SupplierProfiles.Id  --left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID --   left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id	--left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id	left join BuyerProfiles on embel.BuyerNameId=BuyerProfiles.Id	left join DiscountMethods as currency on currency.Id=embel.CurrencyId	left join UOMs on ord.Order_Uom_ID=UOMs.Id    left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id   -- left join UserMappings on UserMappings.Id=ord.Dealing_Merchant_ID  --left join    AddConsumptionFormForEmblishmentCosts embeCnsmtion on embeCnsmtion.Id=embelChild.EmbelCnsmtnId	--left join FabricCosts fabCst on fabCst.PreCostingId=preCst.PrecostingId 	--and fabCst.BodyPartId=embelChild.BodyPartId 	--left join GarmentsItemEntries as itm on embeCnsmtion.GmtsItem=itm.Id     -- left join FabricColorSensitivities clrSensitive on clrSensitive.FabricId=fabCst.Id   left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)	--left join TblRegionInfoes as country on embel.CountryId=country.RegionID	    	 	    where  --  and cnsmtionEntryFrm.TotalQty>0  -- IsTrimBookingComplete=0 and embel.Level='JOB level'and     preCst.PrecostingId is not null   AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END   AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE embel.Id END  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END       order by embelChild.Gmtssizes   End
GO
/****** Object:  StoredProcedure [dbo].[EmbelishmentBookingPoWiseRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[EmbelishmentBookingPoWiseRpt]
(
    @BookingId Int,
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int 
	 
)
AS
BEGIN
  
   select 
 ord.JobNo,
 ord.Style_Ref,
 ord.Repeat_No_Job,
  BuyerWiesSeasons.SeasonName,
 BuyerProfiles.ContactName,
 embel.Id,
 embel.Level,
 embel.WoNo as BookingNo,
  emblTotalQty.TotalBookingQnty,
 embel.WODate as BookingDate,
 embel.DeliveryDate,
 dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as PoQnty,
 currency.DiscountMethodName as currencyName,
userDlngMrcnd.FullName as DealingMarchand,
 embel.PayMode,
  embel.Remarks,
   embel.Source,
    embel.Attention,
  embelChild.EmbelCostId,
  embelChild.Woq,
  embelChild.Rate,
  embelChild.Amount,
 SupplierProfiles.SupplierName,
 embelChild.EmbName,
 embelChild.BodyPart,
 embelChild.EmbType ,
 
 embeCnsmtion.PoNo,
   embelChild.GarmentesItem,
   itm.ItemName,
 embeCnsmtion.GmtsColor,
embeCnsmtion.Gmtssizes,
(case when embeCnsmtion.Cons>0 then embeCnsmtion.ConsFromSizeQnty else 0 end) as ConsFromSizeQnty,
-- fabCst.Id as FabricCostId,
 preCst.PrecostingId ,
 (select top(1) BookingQnty from  getEmblBookingQnty(embel.Id)) as BookingQnty
 --dbo.GetColorSensitivityByFabricId(fabCst.Id) as ContrastColor
 --clrSensitive.ContrastColor
 --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id)

 
 from MultipleJobWiseEmbellishmentWorkOrders as embel 
 left join   EmbellishmentWODetailsChilds embelChild on embelChild.EmbellishmentMasterId= embel.Id
  left join  EmbellishmentCosts as embelCost on embelChild.EmbelCostId=embelCost.Id
 left join PreCostings as preCst on preCst.PrecostingId=embelCost.PrecostingId 
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 left join SupplierProfiles on embel.SupplierNameId=SupplierProfiles.Id 
  
  --left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 --   left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
	--left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
	left join BuyerProfiles on embel.BuyerNameId=BuyerProfiles.Id
	left join DiscountMethods as currency on currency.Id=embel.CurrencyId
	left join UOMs on ord.Order_Uom_ID=UOMs.Id 
   left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id
    left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
  left join    AddConsumptionFormForEmblishmentCosts embeCnsmtion on embeCnsmtion.EmbelCostId=embelChild.EmbelCostId
	--left join FabricCosts fabCst on fabCst.PreCostingId=preCst.PrecostingId 
	--and fabCst.BodyPartId=embelChild.BodyPartId 
	left join GarmentsItemEntries as itm on embeCnsmtion.GmtsItem=itm.Id  
   -- left join FabricColorSensitivities clrSensitive on clrSensitive.FabricId=fabCst.Id

	--left join TblRegionInfoes as country on embel.CountryId=country.RegionID
	
    left join  getEmbelTotalBookingQnty() emblTotalQty on emblTotalQty.woNo=embel.WoNo
	 
	  
  where 
  embeCnsmtion.Cons>0
  and 
 embel.Level='PO level'and 
    preCst.PrecostingId is not null 
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE embel.Id END
  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
       
  End
GO
/****** Object:  StoredProcedure [dbo].[EmbellishmentCostRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[EmbellishmentCostRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
  EmbTyp.Id,
 EmbTyp.TypeName,
 EmblCost.EmbelName,
 EmblCost.Rate,
  EmblCost.Amount,
  EmblCost.Cons,
 BdyPrtEny.BodyPartFullName,
 TblRegInfo.Region_Name,
 Suplir.SupplierName,
 EmblCost.Rate*(dbo.GetPoQuantityByOrderId(prcStng.OrderId)/12) as TotalAmount,
  dbo.GetPoQuantityByOrderId(prcStng.OrderId)/12 as TotalCons
 from  EmbellishmentCosts as EmblCost
left join EmbellishmentTypes as EmbTyp on EmblCost.EmbelTypeId=EmbTyp.Id
left join BodyPartEntries as BdyPrtEny on EmblCost.BodyPartId=BdyPrtEny.Id
left join TblRegionInfoes as TblRegInfo on EmblCost.CountryId=TblRegInfo.RegionID
left join SupplierProfiles as Suplir on EmblCost.SupplierId=Suplir.Id
left join  PreCostings as prcStng on prcStng.PrecostingId=EmblCost.PrecostingId  
where prcStng.OrderId=@InitialOrderId
END

GO
/****** Object:  StoredProcedure [dbo].[ExportFileNumbers]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[ExportFileNumbers]
as
Begin
with FileWithBankRefAndInvoice as( select Id as BankRefId,
     ExportInvoiceIds,InternalFileNo
     from BnkRefExportInvoiceLcOrScConectivity()
     group by Id,ExportInvoiceIds,InternalFileNo)
     select STRING_AGG(BankRefId,',')BankRefIds,
     STRING_AGG(ExportInvoiceIds,',')ExportInvoiceIds,
     InternalFileNo from FileWithBankRefAndInvoice Group By InternalFileNo
End
GO
/****** Object:  StoredProcedure [dbo].[ExportInvoiceByLcBudget]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[ExportInvoiceByLcBudget]    @LcId intAS  Begin SET NOCOUNT ON;  with cte as (select lcDtls.*             from  ExportLCEntryDetails lcDtls where ExportLCMasterId=@LcId),   ExportInvInfo as (select OrderId,sum(ISNULL(CurrInvoiceQnty,0)) as attchQty                      from  ExportInformationDetails                      where OrderId in(select PoId from cte)					 group by OrderId)      select cte.*,             case when exi.attchQty is not null and exi.attchQty>0 then		   (cte.AttachedQty-exi.attchQty) else cte.AttachedQty end as PoBalance,			 0.0  as ExFactoryQty,			 0.0 as CumuInvQty,			 0.0 as CumuInvVlue,             '' as Merchandiser,			 '' as ProductionSource,			 '' as Brand ,			 exi.attchQty			 from cte			 left join ExportInvInfo exi on exi.OrderId=cte.PoId			 where  case when exi.attchQty is not null and exi.attchQty>0 then		   (cte.AttachedQty-exi.attchQty) else cte.AttachedQty end>0End
GO
/****** Object:  StoredProcedure [dbo].[ExportInvoiceByScBudget]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   CREATE PROCEDURE [dbo].[ExportInvoiceByScBudget]    @ScId intAS  Begin SET NOCOUNT ON;  with cte as (select scDtls.*             from  SalesContractEntryDetails scDtls where SalesContractEntryId=@ScId),   ExportInvInfo as (select OrderId,sum(ISNULL(CurrInvoiceQnty,0)) as attchQty                      from  ExportInformationDetails                      where OrderId in(select PoId from cte)					 group by OrderId)      select cte.*,            case when exi.attchQty is not null and exi.attchQty>0 then		   (cte.AttachQty-exi.attchQty) else cte.AttachQty end as PoBalance,			 0.0  as ExFactoryQty,			 0.0 as CumuInvQty,			 0.0 as CumuInvVlue,             '' as Merchandiser,			 '' as ProductionSource,			 '' as Brand 			 			 from cte			 left join ExportInvInfo exi on exi.OrderId=cte.PoId 			 where (case when exi.attchQty is not null and exi.attchQty>0 then		   (cte.AttachQty-exi.attchQty) else cte.AttachQty end)>0End
GO
/****** Object:  StoredProcedure [dbo].[ExportLcStatementRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROCEDURE [dbo].[ExportLcStatementRpt](    @RealizeId int,    @BankRefOrBilId int ,    @InternalFileNo varchar(200))ASBEGIN with cte as (select rlz.* from BnkRefExportInvoiceLcOrScConectivity() bnk         left join ExportProceedsRealizations rlz on rlz.BillOrInvoiceId=bnk.Id 		where @InternalFileNo=case when @InternalFileNo='' then '' else bnk.InternalFileNo end		and rlz.Id is not null  ),TotalInvoiceQty as(  select d.Id,sum(expDtls.InvoiceQuantity)InvoiceQuantity from DocSubmissiontoBanks d   cross apply string_split(ExportIds,',') left join  ExportInformationDetailsSubs expDtls on expDtls.ExportInvoiceId=value group by d.Id),TotalExtraCost as (Select ec.InvoiceId,sum(Amount)TotalAmount from ExtraCommercialCost ec group by InvoiceId),ExtraInoviceCommercialCst as ( select * from  (   select cc.InvoiceId,Replace(Replace(Replace(Rtrim(Ltrim(Replace(Replace(Replace(ecc.Name,'/','')   ,' ',''),'-',''))),'(',''),')',''),'.','')CostName,   cc.Amount   from ExtraCommercialCost cc left join StaticValueExtraCommercialCost eccon ecc.Id=cc.CommercialCostId)as ExtraCommercialCostpivot(   sum(Amount) for CostName in ([TransPortBill],											[CNFBill],											[BLFee],											[CoFee],											[GSPRex],											[CourirCost],											[HandingCharge],											[ShortingCost],											[SpecialCost],											[PortDamage]										)                         )as pivot_table), DistributionsPivotTbl as ( select * from  (   select MasterId,Replace(Replace(Replace(Rtrim(Ltrim(Replace(Replace(Replace(AccountHead,'/','')   ,' ',''),'-',''))),'(',''),')',''),'.','')AccountHead,   DocumentCurrency   FROM ExportProceedsRealizationDistributions)as Distributionspivot(   sum(DocumentCurrency) for AccountHead in ([ERQFCADAC],											[LTRMPI],											[AcceptCommCharge],											[AddConfirmationChange],											[AdditionalTax],											[AdvanceAC],											[AdvanceIncomeTexAIT],											[AirReleaseChargesforDocumentdelay],											[AmendmentCharge],											[ApplicationFormFee],											[AzofreecertTeTestreport],											[BTBMarginBUP],											[BTBMarginForeign],											[BTBMarginLocal],											[BTBMarginDFCBLODADAC],											[BuyingCommission],											[BankCharge],											[BankCommission],											[BankGuaranteeCharge],											[BiSalamPC],											[BuyerDiscripencyFee],											[CBMDiscrepency],											[CCAccount],											[CCHYPOAC],											[CDAccount],											[CashIncentiveloan],											[CashSecurityAC],											[CentralFund],											[CommissionInLieuofExchangeCILE],											[CourierCharge],											[DemandLoan],											[DiscountAC],											[DiscountedtoBuyer],											[DocumentExaminationFee],											[DocumentTracercharge],											[EDFAC],											[ExciseDuty],											[ExpCharge],											[ExportCashCredit],											[ExportReserveMargin],											[FDBCCommission],											[FDRBuildup],											[FCBPAR],											[FCBPR],											[FTTTR],											[ForceLoan],											[ForeignCollectionCharge],											[ForeignCommission],											[GeneralAC],											[HPSM],											[IBBAC],											[IFDBCLiability],											[ImportMarginAC],											[InsuranceCoverage],											[Interest],											[InterestForFactoringg],											[LCGoodsReleasingNOCCharge],											[LCTransferringCharge],											[LIM],											[LateInspectionpenalty],											[Latepresentationcharges],											[Lateshipmentpenalty],											[LoanAC],											[LocalCommission],											[LocalCollectionCharge],											[LongTermLoanSecured],											[LongTermLoanUnsecured])                         )as pivot_table),						 DeductionPivotTbl as ( select * from  (   select MasterId,Replace(Replace(Rtrim(Ltrim(Replace(Replace(Replace(AccountHead,'/','')   ,' ',''),'-',''))),'(',''),')','')AccountHead,   DocumentCurrency   FROM ExportProceedsRealizationDeductionsatSources)as Distributionspivot(   sum(DocumentCurrency) for AccountHead in ([ERQFCADAC],											[LTRMPI],											[AcceptCommCharge],											[AddConfirmationChange],											[AdditionalTax],											[AdvanceAC],											[AdvanceIncomeTexAIT],											[AirReleaseChargesforDocumentdelay],											[AmendmentCharge],											[ApplicationFormFee],											[AzofreecertTeTestreport],											[BTBMarginBUP],											[BTBMarginForeign],											[BTBMarginLocal],											[BTBMarginDFCBLODADAC],											[BuyingCommission],											[BankCharge],											[BankCommission],											[BankGuaranteeCharge],											[BiSalamPC],											[BuyerDiscripencyFee],											[CBMDiscrepency],											[CCAccount],											[CCHYPOAC],											[CDAccount],											[CashIncentiveloan],											[CashSecurityAC],											[CentralFund],											[CommissionInLieuofExchangeCILE],											[CourierCharge],											[DemandLoan],											[DiscountAC],											[DiscountedtoBuyer],											[DocumentExaminationFee],											[DocumentTracercharge],											[EDFAC],											[ExciseDuty],											[ExpCharge],											[ExportCashCredit],											[ExportReserveMargin],											[FDBCCommission],											[FDRBuildup],											[FCBPAR],											[FCBPR],											[FTTTR],											[ForceLoan],											[ForeignCollectionCharge],											[ForeignCommission],											[GeneralAC],											[HPSM],											[IBBAC],											[IFDBCLiability],											[ImportMarginAC],											[InsuranceCoverage],											[Interest],											[InterestForFactoringg],											[LCGoodsReleasingNOCCharge],											[LCTransferringCharge],											[LIM],											[LateInspectionpenalty],											[Latepresentationcharges],											[Lateshipmentpenalty],											[LoanAC],											[LocalCommission],											[LocalCollectionCharge],											[LongTermLoanSecured],											[LongTermLoanUnsecured])                         )as pivot_table),TotalDistributions as (select MasterId,sum(DocumentCurrency)as TotalDistribution from ExportProceedsRealizationDistributions                       group by MasterId),TotalDeduction as (select MasterId,sum(DocumentCurrency)as TotalDeduction from ExportProceedsRealizationDeductionsatSources                       group by MasterId) select cte.*,invQ.InvoiceQuantity as OriginalInvoiceQty,'PCS' as Uom,td.TotalDistribution,tde.TotalDeduction,bp.ContactName as BuyerName,cmny.Company_Name,currncy.DiscountMethodName as CurrencyName, isnull(dp.ERQFCADAC,0) as ERQFCADACDistribute,isnull(dp.LTRMPI,0) as LTRMPIDistribute,isnull(dp.AcceptCommCharge,0) as AcceptCommChargeDistribute,isnull(dp.AddConfirmationChange,0) as AddConfirmationChangeDistribute,isnull(dp.AdditionalTax,0) as AdditionalTaxDistribute,isnull(dp.AdvanceAC,0) as AdvanceACDistribute,isnull(dp.AdvanceIncomeTexAIT,0) as AdvanceIncomeTexAITDistribute,isnull(dp.AirReleaseChargesforDocumentdelay,0) as AirReleaseChargesforDocumentdelayDistribute,isnull(dp.AmendmentCharge,0) as AmendmentChargeDistribute,isnull(dp.ApplicationFormFee,0) as ApplicationFormFeeDistribute,isnull(dp.AzofreecertTeTestreport,0) as AzofreecertTeTestreportDistribute,isnull(dp.BTBMarginBUP,0) as BTBMarginBUPDistribute,isnull(dp.BTBMarginForeign,0) as BTBMarginForeignDistribute,isnull(dp.BTBMarginLocal,0) as BTBMarginLocalDistribute,isnull(dp.BTBMarginDFCBLODADAC,0) as BTBMarginDFCBLODADACDistribute,isnull(dp.BuyingCommission,0) as BuyingCommissionDistribute,isnull(dp.BankCharge,0) as BankChargeDistribute,isnull(dp.BankCommission,0) as BankCommissionDistribute,isnull(dp.BankGuaranteeCharge,0) as BankGuaranteeChargeDistribute,isnull(dp.BiSalamPC,0) as BiSalamPCDistribute,isnull(dp.BuyerDiscripencyFee,0) as BuyerDiscripencyFeeDistribute,isnull(dp.CBMDiscrepency,0) as CBMDiscrepencyDistribute,isnull(dp.CCAccount,0) as CCAccountDistribute,isnull(dp.CCHYPOAC,0) as CCHYPOACDistribute,isnull(dp.CDAccount,0) as CDAccountDistribute,isnull(dp.CashIncentiveloan,0) as CashIncentiveloanDistribute,isnull(dp.CashSecurityAC,0) as CashSecurityACDistribute,isnull(dp.CentralFund,0) as CentralFundDistribute,isnull(dp.CommissionInLieuofExchangeCILE,0) as CommissionInLieuofExchangeCILEDistribute,isnull(dp.CourierCharge,0) as CourierChargeDistribute,isnull(dp.DemandLoan,0) as DemandLoanDistribute,isnull(dp.DiscountAC,0) as DiscountACDistribute,isnull(dp.DiscountedtoBuyer,0) as DiscountedtoBuyerDistribute,isnull(dp.DocumentExaminationFee,0) as DocumentExaminationFeeDistribute,isnull(dp.DocumentTracercharge,0) as DocumentTracerchargeDistribute,isnull(dp.EDFAC,0) as EDFACDistribute,isnull(dp.ExciseDuty,0) as ExciseDutyDistribute,isnull(dp.ExpCharge,0) as ExpChargeDistribute,isnull(dp.ExportCashCredit,0) as ExportCashCreditDistribute,isnull(dp.ExportReserveMargin,0) as ExportReserveMarginDistribute,isnull(dp.FDBCCommission,0) as FDBCCommissionDistribute,isnull(dp.FDRBuildup,0) as FDRBuildupDistribute,isnull(dp.FCBPAR,0) as FCBPARDistribute,isnull(dp.FCBPR,0) as FCBPRDistribute,isnull(dp.FTTTR,0) as FTTTRDistribute,isnull(dp.ForceLoan,0) as ForceLoanDistribute,isnull(dp.ForeignCollectionCharge,0) as ForeignCollectionChargeDistribute,isnull(dp.ForeignCommission,0) as ForeignCommissionDistribute,isnull(dp.GeneralAC,0) as GeneralACDistribute,isnull(dp.HPSM,0) as HPSMDistribute,isnull(dp.IBBAC,0) as IBBACDistribute,isnull(dp.IFDBCLiability,0) as IFDBCLiabilityDistribute,isnull(dp.ImportMarginAC,0) as ImportMarginACDistribute,isnull(dp.InsuranceCoverage,0) as InsuranceCoverageDistribute,isnull(dp.Interest,0) as InterestDistribute,isnull(dp.InterestForFactoringg,0) as InterestForFactoringgDistribute,isnull(dp.LCGoodsReleasingNOCCharge,0) as LCGoodsReleasingNOCChargeDistribute,isnull(dp.LCTransferringCharge,0) as LCTransferringChargeDistribute,isnull(dp.LIM,0) as LIMDistribute,isnull(dp.LateInspectionpenalty,0) as LateInspectionpenaltyDistribute,isnull(dp.Latepresentationcharges,0) as LatepresentationchargesDistribute,isnull(dp.Lateshipmentpenalty,0) as LateshipmentpenaltyDistribute,isnull(dp.LoanAC,0) as LoanACDistribute,isnull(dp.LocalCommission,0) as LocalCommissionDistribute,isnull(dp.LocalCollectionCharge,0) as LocalCollectionChargeDistribute,isnull(dp.LongTermLoanSecured,0) as LongTermLoanSecuredDistribute,isnull(dp.LongTermLoanUnsecured,0) as LongTermLoanUnsecuredDistribute,--DeductionColumnStart here..isnull(dep.ERQFCADAC,0) as ERQFCADACDeduct,isnull(dep.LTRMPI,0) as LTRMPIDeduct,isnull(dep.AcceptCommCharge,0) as AcceptCommChargeDeduct,isnull(dep.AddConfirmationChange,0) as AddConfirmationChangeDeduct,isnull(dep.AdditionalTax,0) as AdditionalTaxDeduct,isnull(dep.AdvanceAC,0) as AdvanceACDeduct,isnull(dep.AdvanceIncomeTexAIT,0) as AdvanceIncomeTexAITDeduct,isnull(dep.AirReleaseChargesforDocumentdelay,0) as AirReleaseChargesforDocumentdelayDeduct,isnull(dep.AmendmentCharge,0) as AmendmentChargeDeduct,isnull(dep.ApplicationFormFee,0) as ApplicationFormFeeDeduct,isnull(dep.AzofreecertTeTestreport,0) as AzofreecertTeTestreportDeduct,isnull(dep.BTBMarginBUP,0) as BTBMarginBUPDeduct,isnull(dep.BTBMarginForeign,0) as BTBMarginForeignDeduct,isnull(dep.BTBMarginLocal,0) as BTBMarginLocalDeduct,isnull(dep.BTBMarginDFCBLODADAC,0) as BTBMarginDFCBLODADACDeduct,isnull(dep.BuyingCommission,0) as BuyingCommissionDeduct,isnull(dep.BankCharge,0) as BankChargeDeduct,isnull(dep.BankCommission,0) as BankCommissionDeduct,isnull(dep.BankGuaranteeCharge,0) as BankGuaranteeChargeDeduct,isnull(dep.BiSalamPC,0) as BiSalamPCDeduct,isnull(dep.BuyerDiscripencyFee,0) as BuyerDiscripencyFeeDeduct,isnull(dep.CBMDiscrepency,0) as CBMDiscrepencyDeduct,isnull(dep.CCAccount,0) as CCAccountDeduct,isnull(dep.CCHYPOAC,0) as CCHYPOACDeduct,isnull(dep.CDAccount,0) as CDAccountDeduct,isnull(dep.CashIncentiveloan,0) as CashIncentiveloanDeduct,isnull(dep.CashSecurityAC,0) as CashSecurityACDeduct,isnull(dep.CentralFund,0) as CentralFundDeduct,isnull(dep.CommissionInLieuofExchangeCILE,0) as CommissionInLieuofExchangeCILEDeduct,isnull(dep.CourierCharge,0) as CourierChargeDeduct,isnull(dep.DemandLoan,0) as DemandLoanDeduct,isnull(dep.DiscountAC,0) as DiscountACDeduct,isnull(dep.DiscountedtoBuyer,0) as DiscountedtoBuyerDeduct,isnull(dep.DocumentExaminationFee,0) as DocumentExaminationFeeDeduct,isnull(dep.DocumentTracercharge,0) as DocumentTracerchargeDeduct,isnull(dep.EDFAC,0) as EDFACDeduct,isnull(dep.ExciseDuty,0) as ExciseDutyDeduct,isnull(dep.ExpCharge,0) as ExpChargeDeduct,isnull(dep.ExportCashCredit,0) as ExportCashCreditDeduct,isnull(dep.ExportReserveMargin,0) as ExportReserveMarginDeduct,isnull(dep.FDBCCommission,0) as FDBCCommissionDeduct,isnull(dep.FDRBuildup,0) as FDRBuildupDeduct,isnull(dep.FCBPAR,0) as FCBPARDeduct,isnull(dep.FCBPR,0) as FCBPRDeduct,isnull(dep.FTTTR,0) as FTTTRDeduct,isnull(dep.ForceLoan,0) as ForceLoanDeduct,isnull(dep.ForeignCollectionCharge,0) as ForeignCollectionChargeDeduct,isnull(dep.ForeignCommission,0) as ForeignCommissionDeduct,isnull(dep.GeneralAC,0) as GeneralACDeduct,isnull(dep.HPSM,0) as HPSMDeduct,isnull(dep.IBBAC,0) as IBBACDeduct,isnull(dep.IFDBCLiability,0) as IFDBCLiabilityDeduct,isnull(dep.ImportMarginAC,0) as ImportMarginACDeduct,isnull(dep.InsuranceCoverage,0) as InsuranceCoverageDeduct,isnull(dep.Interest,0) as InterestDeduct,isnull(dep.InterestForFactoringg,0) as InterestForFactoringgDeduct,isnull(dep.LCGoodsReleasingNOCCharge,0) as LCGoodsReleasingNOCChargeDeduct,isnull(dep.LCTransferringCharge,0) as LCTransferringChargeDeduct,isnull(dep.LIM,0) as LIMDeduct,isnull(dep.LateInspectionpenalty,0) as LateInspectionpenaltyDeduct,isnull(dep.Latepresentationcharges,0) as LatepresentationchargesDeduct,isnull(dep.Lateshipmentpenalty,0) as LateshipmentpenaltyDeduct,isnull(dep.LoanAC,0) as LoanACDeduct,isnull(dep.LocalCommission,0) as LocalCommissionDeduct,isnull(dep.LocalCollectionCharge,0) as LocalCollectionChargeDeduct,isnull(dep.LongTermLoanSecured,0) as LongTermLoanSecuredDeduct,isnull(dep.LongTermLoanUnsecured,0) as LongTermLoanUnsecuredDeduct,isnull(ecc.TransPortBill,0)ExtraTransPortBill,isnull(ecc.[CNFBill],0)ExtraCNFBill,isnull(ecc.[BLFee],0)ExtraBLFee,isnull(ecc.[CoFee],0)ExtraCoFee,isnull(ecc.[GSPRex],0)ExtraGSPRex,isnull(ecc.[CourirCost],0)ExtraCourirCost,isnull(ecc.[HandingCharge],0)ExtraHandingCharge,isnull(ecc.[ShortingCost],0)ExtraShortingCost,isnull(ecc.[SpecialCost],0)ExtraSpecialCost,isnull(ecc.[PortDamage],0)ExtraPortDamage,ec.TotalAmount as ExtraTotalAmount,0.0 as Balance,cte.BillOrInvoiceIdfrom cte                       left join DistributionsPivotTbl dp on dp.MasterId=cte.Id                      left join DeductionPivotTbl dep on dep.MasterId=cte.Id	                  left join TotalDistributions td on td.MasterId=cte.Id					  left join TotalDeduction tde on tde.MasterId=cte.Id					  left join BuyerProfiles bp on bp.Id=cte.Buyer					  left join TblCompanyInfoes cmny on cmny.CompID=cte.Beneficiary					  left join DiscountMethods currncy on currncy.Id=cte.CurrencyId				    left join TotalInvoiceQty invQ on invQ.Id=cte.BillOrInvoiceId					left join ExtraInoviceCommercialCst ecc on ecc.InvoiceId=cte.BillOrInvoiceId					left join TotalExtraCost ec on ec.InvoiceId=cte.BillOrInvoiceId					where @BankRefOrBilId=case when @BankRefOrBilId=0 then 0 else cte.BillOrInvoiceId end					--cte.BillOrInvoiceId=@BankRefOrBilId		End
GO
/****** Object:  StoredProcedure [dbo].[FabricBookingJobWiseRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE PROC [dbo].[FabricBookingJobWiseRpt]
(
    @BookingId Int,
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int 
	 
)
AS
BEGIN
  
	 select JobNo,
	 Style_Ref,
	Repeat_No_Job,
	 SeasonName,
	ContactName,
	Level,
	BookingNo,
	BookingDate,
	DeliveryDate,
	JobQnty,
	convert(decimal(18,4),TotalBookingJobQty) as TotalBookingJobQty,
	AllStyleRef,
	currencyName,
	DealingMarchand,
	PayMode,
	Remarks,
	 Source,
	Attention,
	 FabricCostId,
	 CnsmtnEntryDia,
	 FabricDescription,
	 GsmWeight,
	fabCnsItemSizes,
	fabCnsDia,
	fabCnsGreyCons,
	fabCnsFinishCons,
	 sum(WoQnty) as WoQnty,
	 sum(GrayFabQnty) as GrayFabQnty,
	 sum(FinishFabQnty) as FinishFabQnty, 
     sum(Amount) as Amount,
	 avg(Rate) as Rate,
	 Uom,

	 SupplierName,

	 PoNumbers,
	 Color,
	FabricColor,
	PrecostingId,
	internalRef,
	 Fileno,
	 ColorTypeName,
	fabCnsPoNoId,
	fabCnsColor,
	fabCnsGmtsSizes,
	SizePannelId,

	sum(fabCnsTotalQty) as fabCnsTotalQty,
	avg(fabCnsRate) as fabCnsRate,
	 sum(fabCnsAmount)as fabCnsAmount,
	sum(fabCnsTotalAmount) as fabCnsTotalAmount,
	0 as fabCnsId,
	RefNo,
	sum(SizeQuantity) as  SizeQuantity from (select 
	 ord.JobNo,
	 ord.Style_Ref,
	 ord.Repeat_No_Job,
	  BuyerWiesSeasons.SeasonName,
	 BuyerProfiles.ContactName,
	 booking.TrimsDyingToMatch as Level,
	 booking.BookingNo,
	 booking.BookingDate,
	 booking.DeliveryDate,
	 dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as JobQnty,
	 (bkngQty.BookingTotalJobQnty) as TotalBookingJobQty,
	-- dbo.GetFabricBookingJObQty(preCst.PrecostingId) as TotalBookingJobQty,
	 dbo.GetFabricBookingAllStyleRefNo(bookinChild.PartialFabricBookingMasterId) as AllStyleRef,
	 currency.DiscountMethodName as currencyName,
	 userDlngMrcnd.FullName as DealingMarchand,
	 booking.PayMode,
	  booking.Remarks,
	   booking.Source,
		booking.Attention,
	  bookinChild.FabricCostId,
	  bookinChild.WoQnty,
	  bookinChild.WoQnty as GrayFabQnty,
	   dbo.GetFabricConsumtionCstByFabricIdNColor(bookinChild.fabCnsId) as  FinishFabQnty, 
	 --(( dbo.GetFabricConsumtionCstByFabricIdNColor(preCst.PrecostingId,fabCost.Id,bookinChild.GmtsColor)*100 )/(100-fabCnsm.TotalProcessLossAvg)) as GrayFabQnty,
	  bookinChild.Rate,
	  bookinChild.Amount,
	  bookinChild.Uom,
	  bookinChild.CnsmtnEntryDia,
	 SupplierProfiles.SupplierName,
	 bdyprt.BodyPartFullName+','+ColorTypes.ColorTypeName+','+bookinChild.FabricDescription as FabricDescription,
	 (select top(1) PoNumbers from GetPoNoNameInStringByOrderId(ord.OrderAutoID)) as PoNumbers,
	-- fabConsumtion.PoNoId,
	--(dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId)) as FabricColor,
	 --(dbo.GetGmtsColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId)) as Color,

	 dbo.TRIM(bookinChild.GmtsColor) as Color,
	(case when fabCost.ColorSizeSensitive='As per Gmts. Color' THEN  bookinChild.GmtsColor else ( case when fabCost.ColorTypeId=9 then dbo.GetStripColorByFabricId(fabCost.Id) else
	(dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId,bookinChild.GmtsColor) ) end) end) 
	as FabricColor,
	 preCst.PrecostingId,
	  preCst.internalRef,
	  preCst.Fileno,
	  fabCost.GsmWeight,
	  ColorTypes.ColorTypeName,
	 -- ((59818/12)*0.663)as FinishFabQnty 
	  --(fabCnsm.TotalFinishConsAvg/12)*( dbo.GetPoQuantityByOrderId(ord.OrderAutoID)) as FinishFabQnty 
 
	 --clrSensitive.ContrastColor
	 --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id)
	 --(preCst.PrecostingId,fabCost.Id,bookinChild.GmtsColor,
	 bookinChild.fabCnsPoNoId,
	 bookinChild.fabCnsColor,
	 bookinChild.fabCnsGmtsSizes,
	 SizeWiseOrderTbl.SizePannelId,
	 bookinChild.fabCnsItemSizes,
	 bookinChild.fabCnsDia,
	 bookinChild.fabCnsGreyCons,
	 fabConsumtion.FinishCons as fabCnsFinishCons,
	 bookinChild.fabCnsTotalQty,
	 bookinChild.fabCnsRate,
	 bookinChild.fabCnsAmount,
	 bookinChild.fabCnsTotalAmount,
	 bookinChild.fabCnsId,
	 bookinChild.RefNo,
	 fabConsumtion.SizeQuantity
    --SizeQuantity=(fabConsumtion.SizeQuantity/(select count(1) from FabricCosts where PreCostingId=preCst.PrecostingId)) 


	 from
	 PartialFabricBookings as booking 
	 left join   PartialFabricBookingItemDtlsChilds bookinChild on bookinChild.PartialFabricBookingMasterId= booking.Id
	 	 left join (select * from FabricBookingAllJobQntyByBkngId()) as bkngQty on bkngQty.BookingId=booking.Id
	  left join  FabricCosts as fabCost on fabCost.Id=bookinChild.FabricCostId
	   
	 left join PreCostings as preCst on preCst.PrecostingId=fabCost.PrecostingId 
 

	 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID

	 left join SupplierProfiles on booking.SupplierProfileId=SupplierProfiles.Id
		left join BuyerProfiles on booking.BuyerProfileId=BuyerProfiles.Id
		left join DiscountMethods as currency on currency.Id=booking.CurrencyId
		left join UOMs on ord.Order_Uom_ID=UOMs.Id 
	   left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id
		left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
	  left join ConsumptionEntryForms fabConsumtion on fabConsumtion.Id=bookinChild.fabCnsId
	  left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId
	  left join BodyPartEntries as bdyprt  on fabCost.BodyPartId=bdyprt.Id 
	  left join (Select preCst.PrecostingId,PoDetID,
			 CAST(szeWiseBrkdwn.ItemId AS varchar(50)) AS item,
			inptPnnl.Input_Pannel_ID,Size,Color,
			szeWiseBrkdwn.ArticleNumber,
			szeWiseBrkdwn.SizePannelId
		 from PreCostings as preCst
		  left join TblPodetailsInfroes poDtls on preCst.OrderId=poDtls.InitialOrderID
		 left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID 
		 left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID
		  where
		   preCst.PrecostingId is not null and  
		    -- preCst.PrecostingId in (20047,20048,20049) and
		   size is not null and Color is not null 
			 group by  
			preCst.PrecostingId,PoDetID, 
		  szeWiseBrkdwn.ItemId,
			inptPnnl.Input_Pannel_ID,
			Size,Color,szeWiseBrkdwn.ArticleNumber,
			szeWiseBrkdwn.SizePannelId) SizeWiseOrderTbl 
			on SizeWiseOrderTbl.PrecostingId=preCst.PrecostingId 
			and SizeWiseOrderTbl.PoDetID=bookinChild.fabCnsPoNoId
			and SizeWiseOrderTbl.ArticleNumber=bookinChild.RefNo
			and SizeWiseOrderTbl.Color=bookinChild.GmtsColor
			and SizeWiseOrderTbl.Size=bookinChild.fabCnsGmtsSizes
 
    
	 
	  
	  where 
	  --trims.ConsUnitGmts>0 
	--  and cnsmtionEntryFrm.TotalQty>0 
	 -- IsTrimBookingComplete=0 and
	 booking.TrimsDyingToMatch='JOB level'and    
		preCst.PrecostingId is not null 
and  bookinChild.PartialFabricBookingMasterId=@BookingId
	--and  bookinChild.PartialFabricBookingMasterId=
	--and bookinChild.PreCostingId=18038
		 
  --AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  --AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  --AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE booking.Id END
  
 ) as tbl
	 group by 
	 JobNo,
	 Style_Ref,
	Repeat_No_Job,
	 SeasonName,
	ContactName,
	Level,
	BookingNo,
	BookingDate,
	DeliveryDate,
	JobQnty,
	 TotalBookingJobQty,
	AllStyleRef,
	currencyName,
	DealingMarchand,
	PayMode,
	Remarks,
	 Source,
	Attention,
	 Uom,

	 SupplierName,

	 PoNumbers,
	 Color,
	FabricColor,
	PrecostingId,
	internalRef,
	 Fileno,

	 ColorTypeName,
	fabCnsPoNoId,
	fabCnsColor,
	fabCnsGmtsSizes,
	SizePannelId,
	fabCnsItemSizes,
	fabCnsDia,
	fabCnsGreyCons,
	fabCnsFinishCons,
	 GsmWeight,
 	 	 FabricCostId,
	 CnsmtnEntryDia,
	FabricDescription,
	RefNo
  order by   PrecostingId,FabricCostId,Color,
	FabricColor,SizePannelId
  End  
 

 
 
GO
/****** Object:  StoredProcedure [dbo].[FabricBookingRptByDiaNFinisCons]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE PROC [dbo].[FabricBookingRptByDiaNFinisCons](    @BookingId Int,	@BuyerId Int,	@jobNoId Int,	@poNoId Int,	@styleRef varchar,	@YearId Int 	 )ASBEGIN    select     JobNo,Style_Ref,Repeat_No_Job,  SeasonName, ContactName,Level, BookingNo, BookingDate, DeliveryDate, JobQnty, TotalBookingJobQty, AllStyleRef, RefNo, currencyName,DealingMarchand, PayMode,  Remarks,   Source,    Attention,  FabricCostId,  Uom, CnsmtnEntryDia, SupplierName,FabricDescription,PoNumbers,Color, FabricColor,  ItemColor,PrecostingId, internalRef,  Fileno,  GsmWeight, ColorTypeName, fabCnsPoNoId, fabCnsColor, fabCnsDia, FinishCons, ProcessLoss,  sum(WoQnty) as WoQnty,  sum(WoQnty) as GrayFabQnty,   sum(FinishFabQnty) as FinishFabQnty,    sum(SizeQuantity) as SizeWiseQuantity,  AVG(Rate) AS Rate,  sum(Amount) as Amount, avg(fabCnsGreyCons) as AvgFabCnsGreyCons, avg(FinishCons) as AvgFabCnsFinishCons, avg(ProcessLoss) as AvgProcessLoss, sum(fabCnsTotalQty) as fabCnsTotalQty, avg(fabCnsRate) as AvgFabCnsRate, sum(fabCnsAmount) as fabCnsAmount, sum(fabCnsTotalAmount) as fabCnsTotalAmount from  (  select  ord.JobNo, ord.Style_Ref, ord.Repeat_No_Job,  BuyerWiesSeasons.SeasonName, BuyerProfiles.ContactName, booking.TrimsDyingToMatch as Level, booking.BookingNo, booking.BookingDate, booking.DeliveryDate, dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as JobQnty,-- dbo.GetFabricBookingJObQty(preCst.PrecostingId) as TotalBookingJobQty (b.jbQnty) as TotalBookingJobQty, dbo.GetFabricBookingAllStyleRefNo(bookinChild.PartialFabricBookingMasterId) as AllStyleRef, currency.DiscountMethodName as currencyName, userDlngMrcnd.FullName as DealingMarchand, booking.PayMode,  booking.Remarks,   booking.Source,    booking.Attention,  bookinChild.FabricCostId,  bookinChild.WoQnty,  bookinChild.WoQnty as GrayFabQnty,   dbo.GetFabricConsumtionCstByFabricIdNColor(bookinChild.fabCnsId) as  FinishFabQnty,  --(( dbo.GetFabricConsumtionCstByFabricIdNColor(preCst.PrecostingId,fabCost.Id,bookinChild.GmtsColor)*100 )/(100-fabCnsm.TotalProcessLossAvg)) as GrayFabQnty,  bookinChild.Rate,  bookinChild.Amount,  bookinChild.Uom,  bookinChild.CnsmtnEntryDia, SupplierProfiles.SupplierName, bdyprt.BodyPartFullName+','+ColorTypes.ColorTypeName+','+bookinChild.FabricDescription as FabricDescription, (select top(1) PoNumbers from GetPoNoNameInStringByOrderId(ord.OrderAutoID)) as PoNumbers,-- fabConsumtion.PoNoId,--(dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId)) as FabricColor, --(dbo.GetGmtsColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId)) as Color, dbo.TRIM(bookinChild.GmtsColor) as Color,(case when fabCost.ColorSizeSensitive='As per Gmts. Color' THEN  bookinChild.GmtsColor else ( case when fabCost.ColorTypeId=9 then dbo.GetStripColorByFabricId(fabCost.Id) else(dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId,bookinChild.GmtsColor) ) end) end) as FabricColor, preCst.PrecostingId,  preCst.internalRef,  preCst.Fileno,  fabCost.GsmWeight,  ColorTypes.ColorTypeName, -- ((59818/12)*0.663)as FinishFabQnty   --(fabCnsm.TotalFinishConsAvg/12)*( dbo.GetPoQuantityByOrderId(ord.OrderAutoID)) as FinishFabQnty   --clrSensitive.ContrastColor --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id) --(preCst.PrecostingId,fabCost.Id,bookinChild.GmtsColor, bookinChild.fabCnsPoNoId, bookinChild.fabCnsColor, bookinChild.fabCnsGmtsSizes, bookinChild.fabCnsItemSizes, bookinChild.fabCnsDia, bookinChild.fabCnsGreyCons, fabConsumtion.FinishCons as fabCnsFinishCons, bookinChild.fabCnsTotalQty, bookinChild.fabCnsRate, bookinChild.fabCnsAmount, bookinChild.fabCnsTotalAmount, bookinChild.fabCnsId, bookinChild.RefNo, fabConsumtion.SizeQuantity,  fabConsumtion.FinishCons, fabConsumtion.ProcessLoss, bookinChild.ItemColor  from PartialFabricBookings as booking  left join     PartialFabricBookingItemDtlsChilds bookinChild on bookinChild.PartialFabricBookingMasterId= booking.Id  left join  FabricCosts as fabCost on fabCost.Id=bookinChild.FabricCostId left join PreCostings as preCst on preCst.PrecostingId=fabCost.PrecostingId  left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID left join SupplierProfiles on booking.SupplierProfileId=SupplierProfiles.Id  --left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID --   left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id	--left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id	left join BuyerProfiles on booking.BuyerProfileId=BuyerProfiles.Id	left join DiscountMethods as currency on currency.Id=booking.CurrencyId	left join UOMs on ord.Order_Uom_ID=UOMs.Id    left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id    left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)  --  left join UserMappings on UserMappings.Id=ord.Dealing_Merchant_ID	--left join   FabricConsumtionTotalNAvgCaluculation() as fabCnsm on fabCnsm.FabricCostId=fabCost.Id  left join ConsumptionEntryForms fabConsumtion on fabConsumtion.Id=bookinChild.fabCnsId  left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId  left join BodyPartEntries as bdyprt  on fabCost.BodyPartId=bdyprt.Id   left join (select   p.PartialFabricBookingMasterId,convert(decimal(18,2), sum(ord.JobQuantity)) jbQnty from PartialFabricBookingItemDtlsChilds p left join PreCostings as preCst on p.PreCostingId=preCst.PrecostingId      left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID   group by p.PartialFabricBookingMasterId ) as b on b.PartialFabricBookingMasterId=bookinChild.PartialFabricBookingMasterId--	left join FabricCosts fabCst on fabCst.PreCostingId=preCst.PrecostingId 	--and fabCst.BodyPartId=trimsChild.BodyPartId   	--left join (select * from GetItemNColorNSizeByPoId()) as clrNSize on clrNSize.PoId=trimsChild.PoDeptId   --left join FabricColorSensitivities clrSensitive on fabCost.Id=clrSensitive.FabricId	--left join TblRegionInfoes as country on trims.CountryId=country.RegionID	    	 	    where   --trims.ConsUnitGmts>0 --  and cnsmtionEntryFrm.TotalQty>0  -- IsTrimBookingComplete=0 and booking.TrimsDyingToMatch='JOB level' and        preCst.PrecostingId is not null 	and  bookinChild.PartialFabricBookingMasterId=@BookingId	and fabConsumtion.FinishCons>0 and fabConsumtion.FinishCons is not null	--AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END -- AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END -- AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE booking.Id END     	)		as tbls   	 	group by  	   JobNo,Style_Ref,RefNo,Repeat_No_Job,  SeasonName, ContactName,Level, BookingNo, BookingDate, DeliveryDate, JobQnty, TotalBookingJobQty, AllStyleRef, currencyName,DealingMarchand, PayMode,  Remarks,   Source,    Attention,  FabricCostId,  Uom, CnsmtnEntryDia, SupplierName,FabricDescription,PoNumbers,Color, FabricColor,PrecostingId, internalRef,  Fileno,  GsmWeight, ColorTypeName, fabCnsPoNoId, fabCnsColor, fabCnsDia, FinishCons, ProcessLoss, ItemColor order by Color  End 
GO
/****** Object:  StoredProcedure [dbo].[FabricCostRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROC [dbo].[FabricCostRpt]
(
	@CmnCompanyId INT,
	@StyleRef nvarchar,
	@OrderId INT,
	@PoNo INT,
	@Buyer	INT
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
 fbNatur.Id,
 fbNatur.FabricNatureName,
 bdyprt.BodyPartFullName+','+ColorTypes.ColorTypeName+','+fbCst.FabricDescription as FabricDescription,
 fbCst.FabricDesPreCostId,
 fbCst.GsmWeight,
 fbCst.WidthDiaType,
 fbCst.ColorSizeSensitive,
 fbCst.Color,
 fbCst.ConsumptionBasis,
 fbCst.Uom,
 fbCst.AvgGreyCons,
 fbCst.Rate,
 fbCst.Amount,
 fbCst.TotalQty,
 fbCst.TotalAmount,
 ColorTypes.ColorTypeName,
 BodyPartTypes.BodyPartTypeName,
 bdyprt.BodyPartFullName,
 gmtsItem.ItemName,
 StcFabSrc.FabricSourceName,
 tbliniOrder.OrderAutoID,
 tbliniOrder.JobNo,
 preCst.PrecostingId,
 preCst.jobQty,
 preCst.StyleRef,
 --dbo.PrecstingtTotalConsCalculation(fbCst.AvgGreyCons,Cnsmtn.SizeQuantity) as TotalCons
 cast(Cnsmtn.TotalCons AS  DECIMAL(18,4)) AS TotalCons
from FabricCosts as fbCst 
left join FabricNatures as fbNatur on fbCst.FabNatureId=fbNatur.Id
left join ColorTypes  on fbCst.ColorTypeId=ColorTypes.Id
left join BodyPartTypes  on fbCst.BodyPartTypeId=BodyPartTypes.Id
left join BodyPartEntries as bdyprt  on fbCst.BodyPartId=bdyprt.Id
left join GarmentsItemEntries as gmtsItem on fbCst.GmtsItemId=gmtsItem.Id
left join StaticFabricSource as StcFabSrc on fbCst.FabricSourceId=StcFabSrc.FabricSourceId
left join PreCostings as preCst on fbCst.PreCostingId=preCst.PrecostingId
left join TblInitialOrders as tbliniOrder on preCst.OrderId=tbliniOrder.OrderAutoID
left join (select FabricCostId,sum((SizeQuantity/12)* GreyCons) TotalCons from ConsumptionEntryForms where FinishCons>0 
group by FabricCostId) Cnsmtn on Cnsmtn.FabricCostId=fbCst.Id

where  tbliniOrder.OrderAutoID=@OrderId 
END


--select PrecostingId,sum((SizeQuantity/12)* GreyCons) from ConsumptionEntryForms where PrecostingId=25093  and FinishCons>0 
--group by PrecostingId 


--select * from PreCostings where OrderId=23104
GO
/****** Object:  StoredProcedure [dbo].[FabricPriceCalculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROC [dbo].[FabricPriceCalculation]
(
	@OfferingCostId INT	
)
AS
BEGIN
   select * from OfferingCostInformations where OfferingCostId=@OfferingCostId  and OfferingCostTypeId<12 order by OfferingCostTypeId
END
GO
/****** Object:  StoredProcedure [dbo].[FcbrStatementBalanceFileWise]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[FcbrStatementBalanceFileWise](@BankRefId int,@filNo nvarchar)as beginwith cte as (select  bnk.InternalFileNo,sum(TotalDeduction.Debited) as shortRealization,  sum(TotalDistributions.Credited+TotalDeduction.Debited)TotalRealization     from(select Id,BankRefOrBillNo,InternalFileNo from BnkRefExportInvoiceLcOrScConectivity()    where Id <>@BankRefId   group by Id,BankRefOrBillNo,InternalFileNo) bnk    left join   ExportProceedsRealizations rlz on rlz.BillOrInvoiceId=bnk.Id   left join (select MasterId,sum(DocumentCurrency)as Credited from ExportProceedsRealizationDistributions                       group by MasterId) as TotalDistributions on TotalDistributions.MasterId=rlz.Id     left join (select MasterId,sum(DocumentCurrency)as Debited from ExportProceedsRealizationDeductionsatSources                       group by MasterId)as  TotalDeduction on TotalDeduction.MasterId=rlz.Id   --where bnk.InternalFileNo in('12ffg') and rlz.Id is not null group by bnk.InternalFileNo )select cte.InternalFileNo as FileNo ,isnull(cte.shortRealization,0)shortRealization,isnull(cte.TotalRealization,0)TotalRealization,(isnull(cte.TotalRealization,0)-isnull(transferAmount.Credit,0))Balance  from cteleft join (select FileNo,sum(Credit)Credit from FCBRStatementEntry  f left join ParticularType p on p.Id=f.ParticularWHERE p.ParticularValue  LIKE '%REC FROM FILE%'group by FileNo) as transferAmount on transferAmount.FileNo=cte.InternalFileNo--left join (select FileNo,sum(Debit)Debit from FCBRStatementEntry -- f left join ParticularType p on p.Id=f.Particular--WHERE p.ParticularValue NOT LIKE '%REC FROM FILE%' group by FileNo) as recieveAmount on recieveAmount.FileNo=cte.InternalFileNoend--select * from  FCBRStatementEntry f left join ParticularType p on p.Id=f.Particular;--select * from  FCBRStatementEntry f left join ParticularType p on p.Id=f.Particular--WHERE p.ParticularValue LIKE '%REC%';--select *   from ParticularType where Id=8--select * from BnkRefExportInvoiceLcOrScConectivity()
GO
/****** Object:  StoredProcedure [dbo].[FCBRStatementRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from FCBRStatementEntry
--select *from DocSubmissiontoBanks
--select * from TblCompanyInfoes
CREATE PROC [dbo].[FCBRStatementRpt](
@BankRefId int,
@FileNo Varchar
)
as begin
select f.*,d.BankRefOrBillNo,prt.ParticularValue from FCBRStatementEntry f left join DocSubmissiontoBanks d on d.Id=f.BankRefId
left join ParticularType prt on prt.Id=f.Particular
where f.BankRefId=@BankRefId
end
GO
/****** Object:  StoredProcedure [dbo].[FlatKnitCollarRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 create PROC [dbo].[FlatKnitCollarRpt](	@BookingId INT	 )ASBEGIN select cNc.*,pfb.RefNo,bp.BodyPartFullName from CollarNCuffs cNc left join PartialFabricBookingItemDtlsChilds pfb on cNc.ChildBkngId=pfb.Id left join BodyPartEntries bp on bp.Id=pfb.BodyPartId where pfb.PartialFabricBookingMasterId=@BookingId and BodyPartFullName='Flat Knit Collar'END
GO
/****** Object:  StoredProcedure [dbo].[FlatKnitCuffRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[FlatKnitCuffRpt](	@BookingId INT	 )ASBEGIN select cNc.*,pfb.RefNo,bp.BodyPartFullName from CollarNCuffs cNc left join PartialFabricBookingItemDtlsChilds pfb on cNc.ChildBkngId=pfb.Id left join BodyPartEntries bp on bp.Id=pfb.BodyPartId where pfb.PartialFabricBookingMasterId=@BookingId and BodyPartFullName='Flat Knit Cuff'END
GO
/****** Object:  StoredProcedure [dbo].[GarmentsCalculation]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROC [dbo].[GarmentsCalculation]
(
	@OfferingCostId INT	
)
AS
BEGIN
   select * from OfferingCostInformations where OfferingCostId=@OfferingCostId  and OfferingCostTypeId>11 order by OfferingCostTypeId
END
GO
/****** Object:  StoredProcedure [dbo].[GetCMDetailsRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetCMDetailsRpt]
(
    @jobNoId Int,
	@styleRef varchar 
)
AS
BEGIN
--Declare @PrecostingId int;
--select @PrecostingId=PrecostingId from PreCostings where OrderId=@jobNoId;
-- select * from CostComponenetsMasterDetails where PreCostingId=4010 and CostComponetId=15;

 --Declare @totalCost decimal=12000000,
 --        @Operator decimal =224.00,
 --        @totalWorkingDay decimal=26.00,
	--	 @totalWorkingHourPerDay decimal=10.00,
	--	 @result decimal(7,4)=00.00 

	--set @result=(select(select(select(@totalCost/@Operator))/@totalWorkingDay)/@totalWorkingHourPerDay)/60
		 
  select 
  --(((totalCost/totalWorkingDay)/Operator)/totalWorkingHourPerDay)/60
   
  CAST( ccm.BudgetedCost AS DECIMAL(18,2) )  as CPM,
  preCst.SewSMV,
 preCst.SewEfficiency
  from 
PreCostings as preCst left join CostComponenetsMasterDetails ccm 
on ccm.PreCostingId=preCst.PrecostingId

  where 
    ccm.CostComponetId=15 
   -- and preCst.PrecostingId is not null and preCst.OrderId=23104
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE preCst.OrderId END
  
  
       End
	   --select * from TblInitialOrders where OrderAutoID=23104
	   --select * from PreCostings where OrderId=23104 and PrecostingId=25093
	   --select * from CostComponenetsMasterDetails where  PreCostingId=25093
GO
/****** Object:  StoredProcedure [dbo].[GetcnsmptnTrimsCstByPreCstNIndxNo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 CREATE PROC [dbo].[GetcnsmptnTrimsCstByPreCstNIndxNo](	@PrecostingId Int,	@TrimsIndexNo int,	@TrimsId Int)ASBEGINSELECT * from ConsumptionEntryFormForTrimsCosts as cnsmptn where cnsmptn.PrecostingId=@PrecostingId AND cnsmptn.TrimsIndexNo=@TrimsIndexNo and TrimCostId=0  End
GO
/****** Object:  StoredProcedure [dbo].[GetcnsmptnWashCstByPreCstNIndxNo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[GetcnsmptnWashCstByPreCstNIndxNo](	@PrecostingId Int,	@WashIndexNo int,	@WashId Int)ASBEGINSELECT * from AddConsumptionFormForGmtWashCosts as cnsmptnwhere cnsmptn.PrecostingId=@PrecostingId AND cnsmptn.WashIndexNo =@WashIndexNo and WashCostId=0  End
GO
/****** Object:  StoredProcedure [dbo].[GetCollarNCuffByFabricCstId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[GetCollarNCuffByFabricCstId]
(
	@FabricCostId Int
)
AS
BEGIN
Select 
cnsmtnForm.PoNoId,
poDtls.PO_No,
cnsmtnForm.Color as gmtsColor,
cnsmtnForm.GmtsSizes,
cnsmtnForm.ItemSizes,
cnsmtnForm.SizeQuantity as GmtsQty,
cnsmtnForm.PrecostingId,
prcst.OrderId
 
 
   from ConsumptionEntryForms as cnsmtnForm 
   left join TblPodetailsInfroes poDtls on poDtls.PoDetID=cnsmtnForm.PoNoId

   left join PreCostings prcst on prcst.PrecostingId=cnsmtnForm.PrecostingId
 
  where cnsmtnForm.FabricCostId=@FabricCostId
   
	Order by  PoDetID,Color,GmtsSizes
  End
GO
/****** Object:  StoredProcedure [dbo].[getColorByOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[getColorByOrderId]
(
	@OrderId Int
)
AS
BEGIN
 select 
szeWiseBrkdwn.Color,szeWiseBrkdwn.ItemId as  item 
 
 from TblInitialOrders as ord left join 
 TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 left join   ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id
 left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID 
 left join   SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID

where szeWiseBrkdwn.Color is not null and ord.OrderAutoID=@OrderId  group by szeWiseBrkdwn.Color,szeWiseBrkdwn.ItemId
END
GO
/****** Object:  StoredProcedure [dbo].[GetColorSizeSensitivityByPreCstNIndxNo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[GetColorSizeSensitivityByPreCstNIndxNo]
(
	@PrecostingId Int,
	@FabricIndexNo int,
	@FabricId Int
)
AS
BEGIN
SELECT * from FabricColorSensitivities as clrsnty
where clrsnty.PrecostingId=@PrecostingId AND clrsnty.FabricIndexNo=@FabricIndexNo and FabricId=0
End
GO
/****** Object:  StoredProcedure [dbo].[GetConversionBudgetByProcess]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
   CREATE PROC [dbo].[GetConversionBudgetByProcess](	@BuyerId Int,	@jobNoId Int,	@poNoId Int,	@styleRef varchar,	@YearId Int ,	@ProcessId Int,	@PFBId Int,	@YPOBookingId Int	 )ASBEGIN   select   BuyerProfiles.ContactName, ord.BuyerID as BuyerId, ord.Style_Ref as StyleRef, ord.JobNo , preCst.Fileno, ord.OrderAutoID , preCst.PrecostingId, pfbitemDtls.Id as PoNoId, --it is actualy partial fabric booking child id '' as Remarks,GarmentsItemEntries.ItemName as GmtsItemName, fabCost.GmtsItemId as GmtsItemId,fabCost.Id as FabricCostId,fabCost.BodyPartId , BodyPartEntries.BodyPartFullName as BodyPartName,fabCost.BodyPartTypeId,BodyPartTypes.BodyPartTypeName,fabCost.FabNatureId,FabricNatures.FabricNatureName,fabCost.ColorTypeId, ColorTypes.ColorTypeName,fabCost.FabricDesPreCostId,fabCost.FabricDescription,fabCost.FabricSourceId,StaticFabricSource.FabricSourceName,fabCost.NominatedSuppId,splr.ContactPerson as NominatedSupplier,fabCost.WidthDiaType,fabCost.GsmWeight,fabCost.ColorSizeSensitive,fabCost.ConsumptionBasis,fabCost.Uom,fabCost.AvgGreyCons,fabCost.Rate,fabCost.Amount,fabCost.TotalQty,fabCost.TotalAmount,fabCost.SuplierId, --(dbo.CheckFabricCstIdExistOrNotForFabBkng(fabCost.Id,fs.Color)) as IsBookingComplete,-- fbC.TotalTotalQty as CnsmtnEntryTotalQty  --fabCost.TotalQty as CnsmtnEntryTotalQty, -- (( dbo.GetFabricConsumtionCstByFabricIdNColor(preCst.PrecostingId,fabCost.Id,fs.Color)*100 )/(100-fbC.TotalProcessLossAvg)) as CnsmtnEntryTotalQty,   fabCost.Amount as CnsmtnEntryAmount,    fabCost.TotalAmount as CnsmtnEntryTotalAmount , --   (Select top(1) Color from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryColor,	-- (Select top(1) GmtsSizes from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as GmtsSizes,	-- 	 (Select top(1) ItemSizes from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as ItemSizes, --(Select top(1) Dia from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryDia, --(Select top(1) ProcessLoss from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryProcess,       cnsmtn.Color   as CnsmtnEntryColor,	  cnsmtn.GmtsSizes  as GmtsSizes,	  cnsmtn.ItemSizes   as ItemSizes,     cnsmtn.Dia  as   CnsmtnEntryDia,     cnsmtn.ProcessLoss   as CnsmtnEntryProcess, fbC.TotalGreyConsAvg , fbc.TotalTotalQty, pfbitemDtls.GmtsColor as GmtsColor, pfbitemDtls.ItemColor as FabricColor,-- dbo.GetGmtsColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId) as GmtsColor,-- dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId,dbo.GetGmtsColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId))  as FabricColor, ProductionProcesses.ProductionProcessName, convCst.Id as ConversionId, convCst.ProcessId, convCst.ProcessLoss, convCst.ReqQty as ConversionReqQty, convCst.AvgReqQty ConvrsnAvgReqQty, convCst.ChargeUnit as ConvrsnChargeUnit, convCst.Amount as ConversionAmount, 0 as CountId,  '' as CountName, 0 as Comp1Id,'' as CompositionName, 0 as percentage, '' as yarnColor, 0 as TypeId,'' as TypeName, 0 as YarnConsQnty, 0 as yarnSupplierId, '' as yarnSupplier, 0 as yarnRate, 0 as yarnAmount, strpClr.Id as strpClrId, strpClr.StripColor, strpClr.Measurement as StrpMeasurment, strpClr.Uom as StrpUom, strpClr.TotalFeeder as StrpTotalFeeder, strpClr.FabricReqQty as StrpFabricReqQty, strpClr.BodyColor as StrpBodyColor, 0 as yrnBkngWoQuantity, 0as  ypoId, '' as  YpoEntryDate,  '' as  ypoWoNumber,  pfb.BookingNo as PfbBookingNo,  pfb.Id as PfbBookingId,   pfb.YearId as PfbYearId,(case when convCst.ProcessId=20 then cnsmtn.FinishCons*(SizeQuantity/12) Else pfbitemDtls.WoQnty End) as pfbChldWoQnty,    0 as ServiceBookingStatus,	cnsmtn.RefNo,	cnsmtn.Id as cnsmtnId     from PartialFabricBookingItemDtlsChilds pfbitemDtls  left join FabricCosts as fabCost on  fabCost.Id=pfbitemDtls.FabricCostId  --left join YarnCosts yc on yc.FabricCostId=pfbitemDtls.FabricCostId --left join YarnPurchaseOrderDetails ypoDtls on yc.Id=ypoDtls.YarnCostId left join ConversionCostForPreCosts convCst on convCst.FabricCostId=fabCost.Id left join PreCostings as preCst on fabCost.PreCostingId=preCst.PrecostingId left join PartialFabricBookings pfb on pfb.Id=pfbitemDtls.PartialFabricBookingMasterId --left join YarnPurchaseOrders ypo on ypo.id=ypoDtls.YarnPurchaseOrderId left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID left join StripColors strpClr on strpClr.FabricCostId=fabCost.Id left join ProductionProcesses on ProductionProcesses.Id=convCst.ProcessId  left join GarmentsItemEntries on fabCost.GmtsItemId=GarmentsItemEntries.Id    left join BodyPartEntries on fabCost.BodyPartId=BodyPartEntries.Id	left join BodyPartTypes on fabCost.BodyPartTypeId=BodyPartTypes.Id	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id	--left join SupplierProfiles on SupplierProfiles.Id=yc.SupplierId	left join SupplierProfiles splr on splr.Id=fabCost.NominatedSuppId	left join ConsumptionEntryForms cnsmtn on cnsmtn.Id=pfbitemDtls.fabCnsId    left join FabricConsumtionTotalNAvgCaluculation() as fbC		 on fabCost.Id=fbC.FabricCostId 		 left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId		-- left join YarnCounts on YarnCounts.Id=yc.CountId		-- left join Compositions on Compositions.Id =yc.Comp1Id		-- left join Typpes on Typpes.Id =yc.TypeId		 left join FabricNatures on FabricNatures.Id=fabCost.FabNatureId		  left join StaticFabricSource on StaticFabricSource.Id=fabCost.FabricSourceId		   where   --fabCost.AvgGreyCons>0  --and dbo.CheckFabricCstIdExistOrNotForFabBkng(fabCost.Id,fs.Color)=0   preCst.PrecostingId is not null   --  and Not Exists(select * from ServiceBookingAllChildDetails  where FabricCostId=pfbitemDtls.FabricCostId and BodyPartId=fabCost.BodyPartId and ProcessId=@ProcessId)   -- and convCst.ProcessId=20    and   -- preCst.PrecostingId=18038 and  --preCst.ApprovalStatus=2 and -- dbo.GetFabricConsumtionCstByFabricIdNColor(preCst.PrecostingId,fabCost.Id,fs.Color)>0    and  @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END  AND @ProcessId= CASE @ProcessId WHEN 0 THEN 0 ELSE convCst.ProcessId END    AND @PFBId= CASE @PFBId WHEN 0 THEN 0 ELSE pfb.Id END         --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END       Order by preCst.PrecostingId,pfbitemDtls.FabricCostId  End 
GO
/****** Object:  StoredProcedure [dbo].[GetConversionCostFabricDescDDL]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROC [dbo].[GetConversionCostFabricDescDDL]
(
	@PrecostingId Int
)
AS
BEGIN
Select 
	fabCst.Id,
	fabCst.FabricDescription,
	fabCst.FabricDesPreCostId,
	(BodyPartEntries.BodyPartFullName+','+fabCst.FabricDescription) as fabDescFromFabricCost,
	BodyPartEntries.BodyPartFullName,
	fabCst.AvgGreyCons 
 from FabricCosts as fabCst
   left join BodyPartEntries on BodyPartEntries.Id=fabCst.BodyPartId 
   where fabCst.PreCostingId=@PrecostingId
  End
GO
/****** Object:  StoredProcedure [dbo].[GetEmbelCostBudgetByJobLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROC [dbo].[GetEmbelCostBudgetByJobLevel]
(
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int,
	@EmbelTypeId Int
	 
)
AS
BEGIN
  select * from ProcessEmbelCostForBkng(@jobNoId,@BuyerId,@YearId,@EmbelTypeId);
 End
GO
/****** Object:  StoredProcedure [dbo].[GetEmbelCostBudgetByPoLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetEmbelCostBudgetByPoLevel]
(
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int ,
	@EmbelTypeId Int
	 
)
AS
BEGIN
 
  select 
BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
 embelConsmption.PoNo as OrderNo,
 embelConsmption.PoId as PoDeptId,
 embel.Id,
  PrecostingId = embel.PrecostingId,
  embel.EmbelName,
    embel.EmbelTypeId,
    embel.BodyPartId,
   embel.CountryId,
   embel.SupplierId,
  ((select dbo.EmbelishmentWorkOrederQntyByPoLevel(embel.Id,embelConsmption.PoId))/12)  as Cons,
  
 -- CAST( ( case when embel.Cons=1 then (emWOqnty.sizeQnty)/12 Else 0 End )  AS DECIMAL(7,4) ) AS Cons,
 embel.Rate,
  embel.Amount,
  embel.Status,              
 (select (CASE WHEN count(Id)



 >0  THEN 1 ELSE 0 END)
   from EmbellishmentWODetailsChilds where EmbelCostId=embel.Id 
   -- and JobOrPoLevel='PO level'
	) as IsEmbellishmentCostBooking ,
 (select dbo.EmbelishmentWorkOrederQntyByPoLevel(embel.Id,embelConsmption.PoId)) as ConsFromconsumption,
 --0 as Ex,
 --0 as RateFromconsumption,
 

     preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
 --   ItemGroups.ItemGroupName as  TrimsGroupName,
   UOMs.UomName,                
(select Items from GetItemNameInStringByOrderId(ord.OrderAutoID)) as GmtsItemName,
EmbellishmentTypes.TypeName as EmbellTypeName,
   BodyPartEntries.BodyPartFullName as BodyPartEntry,
    ord.OrderAutoID as OrderAutoId,
   embel.Id as embellishmentCostId ,
   country.Region_Name as CountryName,
   embelConsmption.GmtsColor,
   embelConsmption.Gmtssizes,
   embelConsmption.Id as EmbelCnsmtnId,
   embelConsmption.RefNo
 
 from EmbellishmentCosts as embel 
 left join AddConsumptionFormForEmblishmentCosts embelConsmption on embelConsmption.EmbelCostId=embel.Id
 left join PreCostings as preCst on embel.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
  
    left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
	left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on ord.Order_Uom_ID=UOMs.Id 
	left join TblRegionInfoes as country on embel.CountryId=country.RegionID
	--left join SupplierProfiles on embel.NominatedSuppId=SupplierProfiles.Id
    left join EmbelConsumtionTotalNAvgCaluculation() as embelTotalNAvgCltn
		 on embel.Id=embelTotalNAvgCltn.EmbelCostId 
	 
	  
  where 
  --embel.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
 -- IsTrimBookingComplete=0 and
    preCst.PrecostingId is not null and preCst.ApprovalStatus=2
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
 -- AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
      AND @EmbelTypeId= CASE @EmbelTypeId WHEN 0 THEN 0 ELSE embel.EmbelTypeId END  
  End
GO
/****** Object:  StoredProcedure [dbo].[GetEmblCstCnsmtnByPreCstNIndxNo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
  CREATE PROC [dbo].[GetEmblCstCnsmtnByPreCstNIndxNo](	@PrecostingId Int,	@EmblIndexNo int,	@EmblId Int)ASBEGINSELECT * from AddConsumptionFormForEmblishmentCosts as cnsmptn             where cnsmptn.PrecostingId=@PrecostingId AND cnsmptn.EmblIndexNo=@EmblIndexNo and EmbelCostId=0  End
GO
/****** Object:  StoredProcedure [dbo].[GetFabricColorSensitivitiesByFabricId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROC [dbo].[GetFabricColorSensitivitiesByFabricId]
(
	@FabricId INT
)
AS
BEGIN
 select * from FabricColorSensitivities
 where FabricId=@FabricId 
END
GO
/****** Object:  StoredProcedure [dbo].[GetFabricConsumptionByFabricId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[GetFabricConsumptionByFabricId](	@FabricId Int)ASBEGINSELECT        cnsmptn.Id, cnsmptn.PoNoId, cnsmptn.PrecostingId, cnsmptn.FabricCostId, cnsmptn.Color,                          cnsmptn.GmtsSizes, cnsmptn.Dia, cnsmptn.ItemSizes, cnsmptn.FinishCons, cnsmptn.ProcessLoss,                          cnsmptn.GreyCons, cnsmptn.Rate, cnsmptn.Amount, cnsmptn.Pcs, cnsmptn.TotalQty,                          cnsmptn.TotalAmount, cnsmptn.Remarks, cnsmptn.SizeQuantity, cnsmptn.JobQnty, cnsmptn.RefNo,                          tblpodtls.PO_No as PoName,cnsmptn.FabricIndexNoFROM            dbo.ConsumptionEntryForms as cnsmptn LEFT OUTER JOIN                         dbo.TblPodetailsInfroes as tblpodtls ON cnsmptn.PoNoId =tblpodtls.PoDetID						 where cnsmptn.FabricCostId=@FabricId  End
GO
/****** Object:  StoredProcedure [dbo].[GetFabricConsumptionByPreCstNIndxNo]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetFabricConsumptionByPreCstNIndxNo](	@PrecostingId Int,	@FabIndexNo int,	@FabricId Int)ASBEGINSELECT        cnsmptn.Id, cnsmptn.PoNoId, cnsmptn.PrecostingId, cnsmptn.FabricCostId, cnsmptn.Color,                          cnsmptn.GmtsSizes, cnsmptn.Dia, cnsmptn.ItemSizes, cnsmptn.FinishCons, cnsmptn.ProcessLoss,                          cnsmptn.GreyCons, cnsmptn.Rate, cnsmptn.Amount, cnsmptn.Pcs, cnsmptn.TotalQty,                          cnsmptn.TotalAmount, cnsmptn.Remarks, cnsmptn.SizeQuantity, cnsmptn.JobQnty, cnsmptn.RefNo,                          tblpodtls.PO_No as PoName,cnsmptn.FabricIndexNoFROM            dbo.ConsumptionEntryForms as cnsmptn LEFT OUTER JOIN                         dbo.TblPodetailsInfroes as tblpodtls ON cnsmptn.PoNoId =tblpodtls.PoDetID						 where cnsmptn.PrecostingId=@PrecostingId AND cnsmptn.FabricIndexNo=@FabIndexNo and cnsmptn.FabricCostId=0  End
GO
/****** Object:  StoredProcedure [dbo].[GetFabricCostBudgetByJobLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
CREATE PROC [dbo].[GetFabricCostBudgetByJobLevel](	@BuyerId Int,	@jobNoId Int,	@styleRef varchar,	@YearId Int,	@JobOrPoLevel varchar,	@FabricSourceId Int	)ASBEGIN   select  ord.BuyerID as BuyerId, ord.Style_Ref as StyleRef, ord.JobNo , --cnsmtionEntryFrm.PoNoId,GarmentsItemEntries.ItemName as GmtsItemName, preCst.PrecostingId,fabCost.Id as Id,GarmentsItemEntries.Id as GmtsItemId,fabCost.BodyPartId ,fabCost.BodyPartTypeId,fabCost.FabNatureId,fabCost.ColorTypeId,fabCost.FabricDesPreCostId,fabCost.FabricSourceId,fabCost.NominatedSuppId,fabCost.WidthDiaType,fabCost.GsmWeight,fabCost.ColorSizeSensitive,fabCost.ConsumptionBasis,fabCost.Uom,fabCost.AvgGreyCons,fabCost.Rate,fabCost.Amount,fabCost.TotalQty,fabCost.TotalAmount,fabCost.SuplierId,fabCost.FabricDescription, (dbo.CheckCnsmptnIdExistOrNotForFabBkng(fabCnsptn.Id)) as IsBookingComplete,  BodyPartEntries.BodyPartFullName as BodyPartName, BodyPartTypes.BodyPartTypeName ,-- fbC.TotalTotalQty as CnsmtnEntryTotalQty  --fabCost.TotalQty as CnsmtnEntryTotalQty, (( dbo.GetFabricConsumtionCstByFabricIdNColor(fabCnsptn.Id)*100 )/(100-fbC.TotalProcessLossAvg)) as CnsmtnEntryTotalQty,   fabCost.Amount as CnsmtnEntryAmount,    fabCost.TotalAmount as CnsmtnEntryTotalAmount , --   (Select top(1) Color from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryColor, --(Select top(1) Dia from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryDia, --(Select top(1) ProcessLoss from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryProcess,fabCnsptn.Color as CnsmtnEntryColor,fabCnsptn.Dia as CnsmtnEntryDia,fabCnsptn.ProcessLoss as CnsmtnEntryProcess, fbC.TotalGreyConsAvg , fbc.TotalTotalQty,  ColorTypes.ColorTypeName, fabCnsptn.Color as Color,dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId,fabCnsptn.Color) as ContrastColor, ord.OrderAutoID , fabCnsptn.PoNoId as fabCnsPoNoId, fabCnsptn.Color as fabCnsColor, fabCnsptn.GmtsSizes as fabCnsGmtsSizes, fabCnsptn.ItemSizes as fabCnsItemSizes, fabCnsptn.Dia as fabCnsDia,   fabCnsptn.GreyCons as fabCnsGreyCons,  fabCnsptn.FinishCons as fabCnsFinishCons,   fabCnsptn.TotalQty as fabCnsTotalQty,    fabCnsptn.Rate as fabCnsRate,    fabCnsptn.Amount as fabCnsAmount,    fabCnsptn.TotalAmount as fabCnsTotalAmount,     fabCnsptn.Id as fabCnsId,	   fabCnsptn.RefNo  from  ConsumptionEntryForms fabCnsptn   left join PreCostings as preCst on fabCnsptn.PreCostingId=preCst.PrecostingId --left join select * from FabricColorSensitivities fs on fs.FabricId=fabCost.Id --left join ConsumptionEntryForms cnsmtionEntryFrm on cnsmtionEntryFrm.FabricCostId=fabCost.Id left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID left join   FabricCosts as fabCost  on fabCnsptn.FabricCostId=fabCost.Id -- left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id  left join GarmentsItemEntries on fabCost.GmtsItemId=GarmentsItemEntries.Id    left join BodyPartEntries on fabCost.BodyPartId=BodyPartEntries.Id	left join BodyPartTypes on fabCost.BodyPartTypeId=BodyPartTypes.Id	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id    left join FabricConsumtionTotalNAvgCaluculation() as fbC		 on fabCost.Id=fbC.FabricCostId 		 left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId  where fabCost.AvgGreyCons>0 and dbo.CheckCnsmptnIdExistOrNotForFabBkng(fabCnsptn.Id)=0  and preCst.PrecostingId is not null and preCst.ApprovalStatus=2  and fabCnsptn.FinishCons>0 --and preCst.PrecostingId=17038 --and dbo.GetFabricConsumtionCstByFabricIdNColor(preCst.PrecostingId,fabCost.Id,fs.Color)>0  and  @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE ord.BuyerId END  AND @FabricSourceId= CASE @FabricSourceId WHEN 0 THEN 0 ELSE fabCost.FabricSourceId END    End
GO
/****** Object:  StoredProcedure [dbo].[GetFabricCostBudgetByPoLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[GetFabricCostBudgetByPoLevel](	@CmnCompanyId INT,	@BuyerId Int,	@JobNo varchar,	@jobNoId Int,	@PoNo varChar,	@PoId  Int,	@styleRef varchar,	@YearId Int,	@JobOrPoLevel varchar)ASBEGIN--DECLARE @stfWorker INT	--IF @StaffWorkBoth=1 SET @stfWorker=2	--IF @StaffWorkBoth=2 SET @stfWorker=1	--IF @StaffWorkBoth=3 SET @stfWorker=3	--IF @DepartmentId = 0 SET @DepartmentId = NULL 	--IF @EmployeeId = 0 SET @EmployeeId = NULL 	--IF @OfficeId = 0 SET @OfficeId = NULL	--IF @SecId IS NULL SET @SecId = 0	--IF @FloorId IS NULL SET @FloorId = 0	--IF @DegId IS NULL SET @DegId=0		 select  ord.BuyerID as BuyerId, ord.Style_Ref as StyleRef, ord.JobNo,poDtls.PO_No as PoNo, --cnsmtionEntryFrm.PoNoId, GarmentsItemEntries.ItemName as GmtsItemName,  preCst.PrecostingId,fabCost.Id as Id,GarmentsItemEntries.Id as GmtsItemId,fabCost.BodyPartId ,fabCost.BodyPartTypeId,fabCost.FabNatureId,fabCost.ColorTypeId,fabCost.FabricDesPreCostId,fabCost.FabricSourceId,fabCost.NominatedSuppId,fabCost.WidthDiaType,fabCost.GsmWeight,fabCost.ColorSizeSensitive,fabCost.ConsumptionBasis,fabCost.Uom,fabCost.AvgGreyCons,fabCost.Rate,fabCost.Amount,fabCost.TotalQty,fabCost.TotalAmount,fabCost.PreCostingId,fabCost.SuplierId,fabCost.FabricDescription,fabCost.IsBookingComplete,  BodyPartEntries.BodyPartFullName as BodyPartName, BodyPartTypes.BodyPartTypeName ,-- fbC.TotalTotalQty as CnsmtnEntryTotalQty  fabCost.TotalQty as CnsmtnEntryTotalQty,   fabCost.Amount as CnsmtnEntryAmount,    fabCost.TotalAmount as CnsmtnEntryTotalAmount , --cnsmtionEntryFrm.Color as CnsmtnEntryColor, --cnsmtionEntryFrm.Dia as CnsmtnEntryDia, --cnsmtionEntryFrm.ProcessLoss as CnsmtnEntryProcess fbC.TotalGreyConsAvg, poDtls.PO_Quantity, dbo.PrecstingtTotalConsCalculation(fbC.TotalGreyConsAvg,poDtls.PO_Quantity) as poWiseBalanceQty--((fbC.TotalGreyConsAvg/12)*poDtls.PO_Quantity)as poWiseBalanceQty2   from FabricCosts as fabCost  left join PreCostings as preCst on fabCost.PreCostingId=preCst.PrecostingId --left join ConsumptionEntryForms cnsmtionEntryFrm on cnsmtionEntryFrm.FabricCostId=fabCost.Id left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id --left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID  --left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID  left join GarmentsItemEntries on fabCost.GmtsItemId=GarmentsItemEntries.Id    left join BodyPartEntries on fabCost.BodyPartId=BodyPartEntries.Id	left join BodyPartTypes on fabCost.BodyPartTypeId=BodyPartTypes.Id	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id    left join FabricConsumtionTotalNAvgCaluculation() as fbC		 on fabCost.Id=fbC.FabricCostId   where fabCost.AvgGreyCons>0 --  and cnsmtionEntryFrm.TotalQty>0   and preCst.PrecostingId is not null   and preCst.ApprovalStatus=2 --after precosting approval data will be load   -- Group by preCst.PrecostingId,fabCost.Id,cnsmtionEntryFrm.PoNoId,ord.JobNo,END
GO
/****** Object:  StoredProcedure [dbo].[GetFabricCostConsumptionForShortFabric]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetFabricCostConsumptionForShortFabric]
(
	 
	@precosting Int,
	@poId int,
	@FabricCostId Int,
	@color varchar,
	@GmtsSizes varchar	
)
AS
BEGIN
 select top(1) *
  from ConsumptionEntryForms 
  where PrecostingId=@precosting and
        PoNoId=@poId and 
		FabricCostId=@FabricCostId and 
		Color=@color and GmtsSizes=@GmtsSizes 
       
  End
GO
/****** Object:  StoredProcedure [dbo].[GetGatePassRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[GetGatePassRpt]
(
    @GetPassId Int 
	 
)
AS
BEGIN
  
  select 
   gpe.Id,
 gpe.GatePassID,
 gpe.CompanyId,
 gpe.Basis,
 gpe.SystemIDChallanNo,
 gpe.FromLocation,
 gpe.Department,
 gpe.Section,
 gpe.WithinGroup,
 gpe.SentTo,
 gpe.ToLocation,
 gpe.OutDate,
 gpe.OutTimeHoure,
 gpe.OutTimeMin,
 gpe.Attention,
 gpe.Returnable,
  gpe.EstReturnDate,
   gpe.DeliveryAs,
    gpe.Purpose,
	 gpe.Carriedby,
	 gpe.SentBy,
	 gpe.VhicleNumber,
	  gpe.Remarks,
	    gpip.Id as childId,
		gpip.MasterId,
		ic.ItemCategoryName as  ItemCategory,
		ssn.value as Sample,
		gpip.ItemDescription,
		gpip.ChallanQty,
		gpip.Quantity,
	    um.UomName as Uom 	  ,
		gpip.Rate,
		gpip.Amount,
		gpip.BuyerOrder,
		gpip.Remarks as childRemarks,
		gpip.NoOfBagOrRoll,
		gpip.TotalCartonQty
 		
from 
GatePassEntries as gpe  left join GatePassEntryItemParts gpip on gpip.MasterId=gpe.Id  
left join UOMs um on um.Id=gpip.Uom
left join ItemCategories ic on ic.Id=gpip.ItemCategory
left join StaticSampleName ssn on ssn.Id=gpip.Sample
where gpe.Id=@GetPassId

  
  

 End  
GO
/****** Object:  StoredProcedure [dbo].[GetInitialConsumption]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROC [dbo].[GetInitialConsumption](	@PrecostingId Int)ASBEGINSelect 	preCst.PrecostingId,JobNo,OrderAutoID, PO_No,PoDetID, 	GarmentsItemEntries.ItemName,	CAST(szeWiseBrkdwn.ItemId AS varchar(50)) AS item ,	--szeWiseBrkdwn.ItemId as item,	cs.Countries,Size,Color,	dbo.GetPoQuantityByOrderId(OrderAutoID) as JobQnty,	sum(PO_Quantity) as PoQuanity,	 sum(inptPnnl.Quantity) as CountryQnty,	sum(szeWiseBrkdwn.Quanity) as sizeQnty,	szeWiseBrkdwn.ArticleNumber,	szeWiseBrkdwn.SizePannelId from PreCostings as preCst left join TblInitialOrders as ord on preCst.OrderId=ord.OrderAutoID  left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID --left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id left join InputPannelPodetails as inptPnnl on poDtls.PoDetID=inptPnnl.Po_details_ID  left join  SizePannelPodetails as szeWiseBrkdwn on szeWiseBrkdwn.InputPannelId=inptPnnl.Input_Pannel_ID left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id left join GarmentsItemEntries on szeWiseBrkdwn.ItemId=GarmentsItemEntries.Id left join TblRegionInfoes as cntry on inptPnnl.CountryID =cntry.RegionID left join CountriesInStringByPoId() cs on cs.PoId=poDtls.PoDetID  where  preCst.PrecostingId=@PrecostingId and   preCst.PrecostingId is not null and     size is not null and Color is not null 	 group by  	preCst.PrecostingId,JobNo,OrderAutoID, PO_No,PoDetID, 	GarmentsItemEntries.ItemName,szeWiseBrkdwn.ItemId,	cs.Countries,Size,Color,szeWiseBrkdwn.ArticleNumber,szeWiseBrkdwn.SizePannelId	Order by szeWiseBrkdwn.SizePannelId --PoDetID,szeWiseBrkdwn.ArticleNumber,Color,Size  End
GO
/****** Object:  StoredProcedure [dbo].[GetMenu]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[GetMenu](	@userId int)ASBEGIN select * from Menu where UserId=@userIdEND
GO
/****** Object:  StoredProcedure [dbo].[GetOrderProfitabilityRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[GetOrderProfitabilityRpt]
(
    @jobNoId Int,
	@styleRef varchar 
)
AS
BEGIN
 
  select 
CnversnCst.PrecostingId,
prductnPrces.Id,
 prductnPrces.ProductionProcessName,
 (CnversnCst.ChargeUnit*CnversnCst.AvgReqQty) as Amount,
 (((CnversnCst.ChargeUnit*CnversnCst.AvgReqQty)/TotalCost)*100 ) as ProcessPercentage,
 preCst.jobQty,
 CnversnCst.AvgReqQty,
 CnversnCst.ChargeUnit,
 CnversnCst.ProcessLoss,
   FabricCost  ,
	TrimsCost  ,
	EmbelCost  ,
	GmtsCost  ,
	CommlCost  ,
	LabTest  ,
	Inspection  ,
	Freight  ,
	CurrierCost  ,
	CertificateCost  ,
	DeffdLcCost  ,
	DesignCost  ,
	StudioCost  ,
	OpertExp  ,
	CMCost  ,
	Interest  ,
	IncomeTax  ,
	DepcAmort ,
	Commission,
	TotalCost,
	PriceDzn,
	MarginDzn ,
	PricePcs ,
	FinalCostPcs,
	Marginpcs,
	fabCost.FabricSourceId,
	cstResult.FabricCostQprice,
	cstResult.TrimsCostQprice,
	cstResult.EmbelCostQprice,
	cstResult.GmtsCostQprice,
	cstResult.CommlCostQprice,
	cstResult.LabTestQprice,
	cstResult.InspectionQprice,
	cstResult.FreightQprice,
	cstResult.CurrierCostQprice,
	cstResult.CertificateCostQprice,
	cstResult.DeffdLcCostQprice,
	cstResult.DesignCostQprice,
	cstResult.StudioCostQprice,
	cstResult.OpertExpQprice,
	cstResult.CMCostQprice,
	cstResult.InterestQprice,
	cstResult.IncomeTaxQprice,
	cstResult.DepcAmortQprice,
	cstResult.CommissionQprice,
	cstResult.TotalCostQprice,
	cstResult.PriceDznQprice,
	cstResult.MarginDznQprice,
	cstResult.PricePcsQprice,
	cstResult.FinalCostPcsQprice,
	cstResult.MarginpcsQprice,
	pcost.FabricPurchaseAmount,
	((pcost.FabricPurchaseAmount/TotalCost)*100) as FabricPurchasePercent,
	(select sum(Amount) from YarnCosts where precostingId=CnversnCst.PrecostingId group by precostingId) as YarnTotalAmount,
	dbo.BudgetCostPercentageCalculation((select sum(Amount) from YarnCosts where precostingId=CnversnCst.PrecostingId group by precostingId),CnversnCst.PrecostingId) as YarnPercentage,
	dbo.BudgetCostPercentageCalculation((select sum(Amount) from ConversionCostForPreCosts where precostingId=CnversnCst.PrecostingId group by precostingId),CnversnCst.PrecostingId) as ConsversionQPercentage,
	dbo.BudgetCostPercentageCalculation((CnversnCst.ChargeUnit*CnversnCst.AvgReqQty),CnversnCst.PrecostingId) as ProcessQPercentage,
	dbo.BudgetCostPercentageCalculation((select sum(Amount) from FabricCosts where FabricSourceId=3 and PreCostingId=CnversnCst.PrecostingId),CnversnCst.PrecostingId) as PurchaseFabricQPercentage
	 
from 
PreCostings as preCst  left join  
ConversionCostForPreCosts CnversnCst on preCst.PrecostingId=CnversnCst.PrecostingId
 left join 
  CostComponentHorizontalResult() as cstResult on cstResult.PrecostingId=CnversnCst.PrecostingId
  --left join fabricCosts as fabCost on fabcost.Id=CnversnCst.FabricCostId
 
left join  FabricCosts as fabCost on fabCost.Id=CnversnCst.FabricCostId
left join ProductionProcesses as prductnPrces on CnversnCst.ProcessId=prductnPrces.Id 
 left join  GetFabricPurchaseCostByPrecostingId() pcost on pcost.PreCostingId= preCst.PrecostingId and pcost.FabricSourceId=3 --Fabric source Id 3 for purchase
	  
  where 
 
    preCst.PrecostingId is not null 
	and preCst.OrderId=23104
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE preCst.OrderId END
  
  order by prductnPrces.Id
       
  End


  --select * from TblInitialOrders
 
GO
/****** Object:  StoredProcedure [dbo].[GetServiceBookingAllMasterDtlsByProcessId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetServiceBookingAllMasterDtlsByProcessId](	@ProcessId Int )ASBEGIN SELECT sbm.Id, sbm.BookingNo,sbm.Month,sbm.Year,                          sbm.BuyerProfileId, BuyerProfiles.ContactName, sbm.CurrencyId, DiscountMethods.DiscountMethodName, sbm.ExchangeRate,                          sbm.BookingDate, sbm.DeliveryDate, sbm.PayMode, sbm.Source,                          sbm.SupplierProfileId, SupplierProfiles.SupplierName, sbm.ReadyToApproved, sbm.Attention,                          sbm.ProcessId, ProductionProcesses.ProductionProcessName, sbm.WithMaterials, sbm.KnitDyeSource,                          sbm.JobOrPoLevel, sbm.ShortOrNot, sbm.FabricNature, sbm.Sensitivity,                          sbm.Remark, sbm.EntryDate, sbm.EntryBy, sbm.Status, sbm.ApproveById,                          sbm.ApproveDate, sbm.ApprovalStatus              FROM   ServiceBookingAllMasterDtls sbm   left JOIN                         BuyerProfiles ON sbm.BuyerProfileId = BuyerProfiles.Id left JOIN                         SupplierProfiles ON sbm.SupplierProfileId = SupplierProfiles.Id left JOIN                         DiscountMethods ON sbm.CurrencyId = DiscountMethods.Id left JOIN                         ProductionProcesses ON sbm.Id = ProductionProcesses.Id       where sbm.ProcessId=@ProcessId  End--ALTER TABLE ServiceBookingAllMasterDtls--DROP COLUMN MonthId;--ALTER TABLE ServiceBookingAllMasterDtls--DROP COLUMN YearId;--  ALTER TABLE ServiceBookingAllMasterDtls--add   Month nvarchar(100);-- ALTER TABLE ServiceBookingAllMasterDtls--add  Year nvarchar(100);
GO
/****** Object:  StoredProcedure [dbo].[GetServiceBookingRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[GetServiceBookingRpt](	@BuyerId Int,	@jobNoId Int,	@styleRef varchar,	@Year Int ,	@MonthName varchar,	@ProcessId Int,	@PFBId Int,	@YPOBookingId Int,	@WoId Int  )ASBEGIN    select pp.ProductionProcessName as ProcessName,
sbm.BookingNo as ServiceBkngNo,
sbm.Attention,sbm.EntryDate as MasterEntryDate,sbm.EntryBy as MasterEntryBy,
sbm.Month,sbm.Year,
yarnPo.WoNumber as YarnBkngNo,
pfb.BookingNo as PfbBookingNo,
bp.ContactName as ServicBkngBuyerName,
bpChild.ContactName as JobBuyerName,
sp.SupplierName as ServcBkngSupplierName,
spChild.SupplierName as FabricSupplierName ,
FabricNatures.FabricNatureName,
 ColorTypes.ColorTypeName,
 fs.FabricSourceName,
sbc.* from ServiceBookingAllChildDetails sbc 
                left JOIN ServiceBookingAllMasterDtls sbm  on sbm.Id=sbc.MasterId
                left JOIN BuyerProfiles bp ON sbm.BuyerProfileId = bp.Id 				left JOIN BuyerProfiles bpChild ON  bpChild.Id=sbc.BuyerId 				left JOIN SupplierProfiles sp ON sbm.SupplierProfileId = sp.Id 				left JOIN SupplierProfiles spChild ON  spChild.Id= sbc.SuplierId				left JOIN DiscountMethods crncy ON sbm.CurrencyId = crncy.Id 				left JOIN ProductionProcesses pp ON sbc.ProcessId = pp.Id
				left join YarnPurchaseOrders yarnPo on yarnPo.Id=sbc.YpoBookingId
				left join PartialFabricBookings pfb on pfb.Id=sbc.PfBookingId
				left join BodyPartTypes on BodyPartTypes.Id=sbc.BodyPartTypeId
				left join FabricNatures on FabricNatures.Id=sbc.FabNatureId
				left join ColorTypes on ColorTypes.Id=sbc.ColorTypeId
				left join StaticFabricSource fs on fs.FabricSourceId=sbc.FabricSourceId
				--where 
				--sbc.ProcessId=20 and
				--sbc.PfBookingId=8012
				--and sbc.OrderAutoID=12039
	   where sbc.PrecostingId is not null and  @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE sbc.OrderAutoID END  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE sbc.BuyerId END  AND @ProcessId= CASE @ProcessId WHEN 0 THEN 0 ELSE sbc.ProcessId END    AND @PFBId= CASE @PFBId WHEN 0 THEN 0 ELSE sbc.PfBookingId END     AND @WoId= CASE @WoId WHEN 0 THEN 0 ELSE sbm.Id END  End 
GO
/****** Object:  StoredProcedure [dbo].[GetShortFabricBookingRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[GetShortFabricBookingRpt]
(
    @BookingId Int,
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int 
	 
)
AS
BEGIN
  
  select 
 ord.JobNo,
 ord.Style_Ref,
 ord.Repeat_No_Job,
  BuyerWiesSeasons.SeasonName,
 BuyerProfiles.ContactName,
 --booking.TrimsDyingToMatch as Level,
 booking.BookingNo,
 booking.BookingDate,
 booking.DeliveryDate,
 dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as JobQnty,
 currency.DiscountMethodName as currencyName,
 userDlngMrcnd.FullName as DealingMarchand,
 booking.PayMode,
  booking.Remarks,
   booking.FabricSource,
   booking.Source,
    booking.Attention,
	booking.BookingMonth,
	booking.BookingYear,
	booking.FabricNature,
	booking.ExchangeRate,
	booking.ShortBookingType,
	location.Location_Name,
	booking.ReadyToApproved,
	booking.OrderNo,
--  bookinChild.FabricCostId,
 -- bookinChild.WoQnty,
 bookinChild.FinishFabric,
    bookinChild.GrayFabric as GrayFabQnty,
  bookinChild.Rate,
  bookinChild.Amount,
  UOMs.UomName,
  bookinChild.DiaOrWidth,
 SupplierProfiles.SupplierName,
 bookinChild.FabDesc as FabricDescription,
 (select top(1) PoNumbers from GetPoNoNameInStringByOrderId(ord.OrderAutoID)) as PoNumbers,
-- fabConsumtion.PoNoId,
--(dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId)) as FabricColor,
 --(dbo.GetGmtsColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId)) as Color,

 bookinChild.GarmentsColor as Color,
--(case when fabCost.ColorSizeSensitive='As per Gmts. Color' THEN  bookinChild.GmtsColor else (dbo.GetContrastOrFabricColorByFabricIdNItemId(fabCost.Id,fabCost.GmtsItemId,bookinChild.GmtsColor)) end) as FabricColor,
bookinChild.FabricColor,
 preCst.PrecostingId,
  preCst.internalRef,
  preCst.Fileno,
  bookinChild.Responsibleperson,
  bookinChild.Reason,
  bookinChild.Departments,
  bookinChild.Itemsize,
  bookinChild.Garmentssize,
  bookinChild.Processloss,
  bookinChild.RmgQty

  --fabCost.GsmWeight,
 -- ColorTypes.ColorTypeName,
 -- (fabCnsm.TotalFinishConsAvg/12)*( dbo.GetPoQuantityByOrderId(ord.OrderAutoID)) as FinishFabQnty 
 --clrSensitive.ContrastColor
 --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id)

 from ShortFabricBookings as booking 
 left join ShortFabricBookingDetails bookinChild on bookinChild.ShortFabricBookingId= booking.Id
  --left join  FabricCosts as fabCost on fabCost.Id=bookinChild.FabricCostId
   left join  TblInitialOrders as ord  on booking.JobNo=ord.JobNo
 left join PreCostings as preCst on preCst.OrderId=ord.OrderAutoID 

 left join SupplierProfiles on booking.SupplierProfileId=SupplierProfiles.Id
  --left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 --   left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
	--left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
	left join BuyerProfiles on booking.BuyerProfileId=BuyerProfiles.Id
	left join DiscountMethods as currency on currency.Id=booking.Currency
	left join UOMs on ord.Order_Uom_ID=UOMs.Id 
   left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id
    left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
 left join TblLocationInfoes location on location.LocationId=booking.SupplierLocation
 --  left join UserMappings on UserMappings.Id=ord.Dealing_Merchant_ID
	--left join FabricConsumtionTotalNAvgCaluculation() as fabCnsm on fabCnsm.FabricCostId=fabCost.Id
  --left join ConsumptionEntryForms fabConsumtion on fabConsumtion.FabricCostId=fabCost.Id
  --left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId
  --left join BodyPartEntries as bdyprt  on fabCost.BodyPartId=bdyprt.Id
--	left join FabricCosts fabCst on fabCst.PreCostingId=preCst.PrecostingId 
	--and fabCst.BodyPartId=trimsChild.BodyPartId   
	--left join (select * from GetItemNColorNSizeByPoId()) as clrNSize on clrNSize.PoId=trimsChild.PoDeptId
   --left join FabricColorSensitivities clrSensitive on fabCost.Id=clrSensitive.FabricId

	--left join TblRegionInfoes as country on trims.CountryId=country.RegionID
	
    
	 
	  
  where 
  --trims.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
 -- IsTrimBookingComplete=0 and
 --booking.TrimsDyingToMatch='JOB level'and    
    preCst.PrecostingId is not null   
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE booking.Id END
  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
   order by   bookinChild.GarmentsColor
  End
GO
/****** Object:  StoredProcedure [dbo].[GetShortFabricCostBudgetByJobLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[GetShortFabricCostBudgetByJobLevel]
(
	@BuyerId Int,
	@jobNoId Int,
	@styleRef varchar,
	@YearId Int,
	@JobOrPoLevel varchar,
	@FabricSourceId Int	
)
AS
BEGIN
 
 select 
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo ,
 --cnsmtionEntryFrm.PoNoId,
GarmentsItemEntries.ItemName as GmtsItemName, 
preCst.PrecostingId,
fabCost.Id as Id,
GarmentsItemEntries.Id as GmtsItemId,
fabCost.BodyPartId ,
fabCost.BodyPartTypeId,
fabCost.FabNatureId,
fabCost.ColorTypeId,
fabCost.FabricDesPreCostId,
fabCost.FabricSourceId,
fabCost.NominatedSuppId,
fabCost.WidthDiaType,
fabCost.GsmWeight,
fabCost.ColorSizeSensitive,
fabCost.ConsumptionBasis,
fabCost.Uom,
fabCost.AvgGreyCons,
fabCost.Rate,
fabCost.Amount,
fabCost.TotalQty,
fabCost.TotalAmount,

fabCost.SuplierId,
fabCost.FabricDescription,

 (select (CASE WHEN count(Id)


 >0  THEN 1 ELSE 0 END)
   from PartialFabricBookingItemDtlsChilds where FabricCostId=fabCost.Id) as IsBookingComplete,
 
 BodyPartEntries.BodyPartFullName as BodyPartName,
 BodyPartTypes.BodyPartTypeName ,
-- fbC.TotalTotalQty as CnsmtnEntryTotalQty
  fabCost.TotalQty as CnsmtnEntryTotalQty,
   fabCost.Amount as CnsmtnEntryAmount,
    fabCost.TotalAmount as CnsmtnEntryTotalAmount ,
    (Select top(1) Color from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryColor,
 (Select top(1) Dia from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryDia,
 (Select top(1) ProcessLoss from ConsumptionEntryForms where FabricCostId=fabCost.Id and GreyCons>0) as CnsmtnEntryProcess,
 fbC.TotalGreyConsAvg ,
 fbc.TotalTotalQty,
 
 ColorTypes.ColorTypeName,
 fs.Color,
 fs.ContrastColor

 
 from FabricCosts as fabCost 
 left join PreCostings as preCst on fabCost.PreCostingId=preCst.PrecostingId
 left join FabricColorSensitivities fs on fs.FabricId=fabCost.Id
 --left join ConsumptionEntryForms cnsmtionEntryFrm on cnsmtionEntryFrm.FabricCostId=fabCost.Id
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID

 
 left join  ItemDetailsOrderEntries as itmDtls on ord.OrderAutoID=itmDtls.order_entry_id

  left join GarmentsItemEntries on fabCost.GmtsItemId=GarmentsItemEntries.Id
    left join BodyPartEntries on fabCost.BodyPartId=BodyPartEntries.Id
	left join BodyPartTypes on fabCost.BodyPartTypeId=BodyPartTypes.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
    left join FabricConsumtionTotalNAvgCaluculation() as fbC
		 on fabCost.Id=fbC.FabricCostId 
		 left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId

  where fabCost.AvgGreyCons>0 
--  and cnsmtionEntryFrm.TotalQty>0 
--and IsBookingComplete=0
  and preCst.PrecostingId is not null 
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @FabricSourceId= CASE @FabricSourceId WHEN 0 THEN 0 ELSE fabCost.FabricSourceId END
  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
       
  End
GO
/****** Object:  StoredProcedure [dbo].[GetShortTrimsCostBudgetByJobLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetShortTrimsCostBudgetByJobLevel]
(
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int 
	 
)
AS
BEGIN
 
  select 
  BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
'' as OrderNo,
 0 as PoDeptId,
 trimCost.Id,
  PrecostingId = trimCost.PrecostingId,
  trimCost.GroupId,
 trimCost.CountryId,
 country.Region_Name as CountryName,
  trimCost.Description,
 trimCost.BrandSupRef,
   trimCost.Remarks,
  trimCost.NominatedSuppId,
  SupplierProfiles.SupplierName,
    trimCost.ConsUOMId,
   trimCost.ConsUnitGmts,
   trimCost.Rate,
    trimCost.Amount,
    trimCost.TotalQty,
    trimCost.TotalAmount,
   trimCost.ApvlReq,
     trimCost.ImagePath,                 
 (select (CASE WHEN count(Id)


 >0  THEN 1 ELSE 0 END)
   from TrimsBookingItemDtlsChilds where TrimCostId=trimCost.Id
    --and OrderAutoId=ord.OrderAutoID and JobOrPoLevel='JOB level'
	) 
	as IsTrimBookingComplete,
 trimsTotalNAvgCltn.TotalTotalQty as ConsFromconsumption,
 --ConsFromconsumption=consumptionEntryFormForTrimsCost.Cons,
 
 0 as Ex,
 (trimCost.Rate) as RateFromconsumption,
-- 0 as RateFromconsumption,
   --RateFromconsumption=consumptionEntryFormForTrimsCost.Rate,
--AmountFromconsumption=consumptionEntryFormForTrimsCost.Amount,
  
 
   preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    ItemGroups.ItemGroupName as  TrimsGroupName,
    UOMs.UomName,
    ord.OrderAutoID as OrderAutoId,
    trimCost.Id as TrimCostId
                             



 --   (Select top(1) Color from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryColor,
 --(Select top(1) Dia from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryDia,
 --(Select top(1) ProcessLoss from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryProcess,
 

 
 from TrimCosts as trimCost 
 left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
    left join ItemGroups on trimCost.GroupId=ItemGroups.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on trimCost.ConsUOMId=UOMs.Id
	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID
	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id
    left join TrimsConsumtionTotalNAvgCaluculation() as trimsTotalNAvgCltn
		 on trimCost.Id=trimsTotalNAvgCltn.TrimsCostId 
	 
	  
  where 
  --trimCost.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
--and IsBookingComplete=0
    preCst.PrecostingId is not null 
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
       
  End
GO
/****** Object:  StoredProcedure [dbo].[GetTblInitialOrderView]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetTblInitialOrderView]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	
	 
 select 
  ord.OrderAutoID,
   ord.JobNo,
   right(ord.JobNo, len(ord.JobNo)-7) as JobNoAfterSplit, 
   ord.CompanyID,
   ord.LocationID,
   ord.BuyerID,
   ord.Style_Ref,
    ord.Style_Description,
      ord.Prod_DeptID,
       ord.Sub_DeptID,
      ord.CurrencyID,
          ord.RegionID,
           ord.Product_CatID,
           ord.Team_Leader_ID,
          ord.Dealing_Merchant_ID,
           ord.BH_Merchant,
            ord.Remarks,
              ord.Shipment_Mode_ID,
               ord.Order_Uom_ID,
              ord.SMV,
                ord.Packing_ID,
               ord.Season_ID,
                 ord.Agent_ID,
                  ord.UserID,
                   ord.Repeat_No_Job,
                 ord.Order_Number,
                  ord.OrderImagePath,
                   ord.factory_merchant,
				    ord.Status,
                    ord.EntryDate,
                     ord.EntryBy,

					TblCompanyInfoes.Company_Name as  CompanyName,

                     TblLocationInfoes.Location_Name as LocationName,

                      BuyerProfiles.ContactName as BuyerName,

                     TblProductionDeptInfoes.ProdDeptName as ProdDeptName,

                      ProductCategories.ProductCategoryName as ProdCatName,

                    

                              UOMs.UomName as OrderUomName,
                             TblPackingInfoes.Packing_Name as PackingName,
 
 
							   userInfTmldr.FullName as TeamLeaderName,
 userDlngMrcnd.FullName as DealingMerchandName ,
 userFctryMrcnd.FullName as FactoryMerchandName,

-- ord.AvgUnitPrice,
 (select cast(ord.AvgUnitPrice as decimal(10,2))) as AvgUnitPrice,
  (select cast(ord.JobQuantity as decimal(10,2))) as JobQuantity,
   (select cast(ord.TotalPrice as decimal(10,2))) as TotalPrice,

  isPrecostingAdded=(case when PreCostings.PrecostingId is not null then 1 else 0 end)
 

 from TblInitialOrders as ord  
 left join TblCompanyInfoes on ord.CompanyID=TblCompanyInfoes.CompID
 left join TblLocationInfoes on ord.LocationID=TblLocationInfoes.LocationId
 left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
 left join  TblProductionDeptInfoes on ord.Prod_DeptID=TblProductionDeptInfoes.ID
 left join ProductCategories on ord.Product_CatID=ProductCategories.Id
 left join UOMs on ord.Order_Uom_ID=UOMs.Id
 --write packing here first create table
 left join TblSeasonInfoes on ord.Season_ID=TblSeasonInfoes.SeasonID
 left join TblAgentInfoes on ord.Agent_ID=TblAgentInfoes.AgentID
 left join TblPackingInfoes on ord.Packing_ID=TblPackingInfoes.PackingID
 left join PreCostings on ord.OrderAutoID=PreCostings.OrderId
 --left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
 --left join TblUserInfoes as userInfTmldr on userInfTmldr.UserId=(select top(1) UserId  from UserMappings where Id=ord.Team_Leader_ID)
 --left join TblUserInfoes as userFctryMrcnd on userFctryMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.factory_merchant)
  left join UserMappings umMrcnd on umMrcnd.Id=ord.Dealing_Merchant_ID
 left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=umMrcnd.UserId
 left join TblUserInfoes as userInfTmldr on userInfTmldr.UserId=umMrcnd.UserId
 left join TblUserInfoes as userFctryMrcnd on userFctryMrcnd.UserId=umMrcnd.UserId


  --left join UserMappings umTmLdr on um.Id=ord.Team_Leader_ID
 -- left join UserMappings umFctryMrchnd on um.Id=ord.factory_merchant
END
GO
/****** Object:  StoredProcedure [dbo].[GetTrimsBookingV3Rpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 

 
CREATE PROC [dbo].[GetTrimsBookingV3Rpt]
(
	@BuyerId Int,
	@jobNoId Int,--this is booking Id
	@styleRef varchar,
	@YearId Int,
	@JobOrPoLevel varchar,
	@GroupId Int	
)
AS
BEGIN
 
SELECT trimBkng.BookingNo, trimBkng.ShipmentMonth, trimBkng.ShipmentYear, 
        trimBkng.CompanyNameId,company.Company_Name, trimBkng.BuyerNameId,byr.ContactName, trimBkng.BookingDate, 
       trimBkng.DeliveryDate, trimBkng.PayMode, trimBkng.CurrencyId,crrncy.DiscountMethodName, trimBkng.SupplierNameId,supp.SupplierName,
        trimBkng.MaterialSource, trimBkng.Attention, trimBkng.ReadyToApproved, trimBkng.Source, 
         trimBkng.Remarks, trimBkng.Level, trimBkng.DeliveryTo, trimBkngChild.TrimsBookingMasterId, 
          trimBkngChild.PrecostingId, trimBkngChild.JobNo
		 , trimBkngChild.OrderAutoId, trimBkngChild.PoDeptId, 
         trimBkngChild.TrimCostId,ord.Style_Ref as OrdNo, trimBkngChild.TrimsGroup, trimBkngChild.Description, 
      trimBkngChild.BrandSup, Round(trimBkngChild.ReqQnty,0)ReqQnty, trimBkngChild.Uom, trimBkngChild.CuWOQ, 
      trimBkngChild.BalWOQ, trimBkngChild.Sensitivity, Round(trimBkngChild.Woq,0)as Woq, trimBkngChild.ExchRate, trimBkngChild.Rate, 
        trimBkngChild.Amount, trimBkngChild.DelvDate, trimBkngChild.JobOrPoLevel, trimBkngChild.GmtsColor,trimBkngChild.ItemColor, 
        trimBkngChild.Gmtssizes, trimBkngChild.GroupId, trimBkngChild.ConsumptionId,'' as Countries,
		supp.AddressOne as SupplierAddress,userDlngMrcnd.FullName as dealingMarchandName,trimBkngChild.RefNo,
		Round(trimBkngChild.PerAccessories,0) as PerAccessories ,
		Round(trimBkngChild.SizeQnty,0) as SizeQnty,
		trimBkngChild.mesurmentDescription,
		preCst.Fileno
		--dbo.GetPoQuantityByOrderId(trimBkngChild.OrderAutoId) as JobQnty
  FROM MultipleJobWiseTrimsBookingV2 trimBkng left JOIN   TrimsBookingItemDtlsChilds trimBkngChild 
                           ON trimBkng.Id = trimBkngChild.TrimsBookingMasterId
						   left join PreCostings preCst on preCst.PrecostingId=trimBkngChild.PrecostingId
						   left join TblCompanyInfoes company on company.CompID=trimBkng.CompanyNameId
						    left join BuyerProfiles byr on byr.Id=trimBkng.BuyerNameId
							left join SupplierProfiles supp on supp.Id=trimBkng.SupplierNameId
							left join DiscountMethods crrncy on crrncy.Id=trimBkng.CurrencyId
							--left join     ConsumptionEntryFormForTrimsCosts cnsmptn on cnsmptn.Id=trimBkngChild.ConsumptionId
							 left join TblInitialOrders ord on ord.JobNo=trimBkngChild.JobNo
							left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
							where
							trimBkngChild.Woq>0
							and
  @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE trimBkng.Id END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE byr.Id END
  AND @GroupId= CASE @GroupId WHEN 0 THEN 0 ELSE trimBkngChild.GroupId END

  End
GO
/****** Object:  StoredProcedure [dbo].[GetTrimsCostBudgetByJobLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 CREATE PROC [dbo].[GetTrimsCostBudgetByJobLevel](	@BuyerId Int,	@jobNoId Int,	@poNoId Int,	@styleRef varchar,	@YearId Int,	@groupId int	 )ASBEGIN  select BuyerName,BuyerId,StyleRef,JobName,OrderNo,PoDeptId,Id,PrecostingId,GroupId,CountryId,CountryName,Description,BrandSupRef,Remarks,NominatedSuppId,SupplierName,ConsUOMId,ConsUnitGmts,Rate,Amount,TotalQty,TotalAmount,ApvlReq,ImagePath,(dbo.IsConsumptionIdExist(ConsumptionId)) as  IsTrimBookingComplete,ConsFromconsumption,Ex,RateFromconsumption,FileNo,InternalRef,TrimsGroupName,UomName,OrderAutoId,TrimCostId,GmtsColor,Gmtssizes,ConsumptionId,GmtsItemId,RefNo,PerAccessories,SizeQnty,mesurmentDescription from(select   BuyerProfiles.ContactName as  BuyerName, ord.BuyerID as BuyerId, ord.Style_Ref as StyleRef, ord.JobNo as JobName,'' as OrderNo, 0 as PoDeptId, trimCost.Id,  PrecostingId = trimCost.PrecostingId,  trimCost.GroupId, trimCost.CountryId, cnsmptnTrims.Countries as CountryName,  trimCost.Description, trimCost.BrandSupRef,   trimCost.Remarks,  trimCost.NominatedSuppId,  SupplierProfiles.SupplierName,    trimCost.ConsUOMId,   trimCost.ConsUnitGmts,   avg(cnsmptnTrims.Rate)as Rate,-- group Avg()   avg(cnsmptnTrims.Amount) as Amount,-- group Avg()   sum(cnsmptnTrims.TotalQty)  as TotalQty,-- group sum()   sum(cnsmptnTrims.TotalAmount)as  TotalAmount,-- group sum()   trimCost.ApvlReq,     trimCost.ImagePath,                  --(select (CASE WHEN count(Id) -->0  THEN 1 ELSE 0 END)--   from TrimsBookingItemDtlsChilds where TrimCostId=trimCost.Id    --and OrderAutoId=ord.OrderAutoID and JobOrPoLevel='JOB level'	--)   0	as IsTrimBookingComplete,-- trimsTotalNAvgCltn.TotalTotalQty as ConsFromconsumption, sum(cnsmptnTrims.TotalQty) as ConsFromconsumption,--sum() --ConsFromconsumption=consumptionEntryFormForTrimsCost.Cons,  0 as Ex, 0 as RateFromconsumption,-- 0 as RateFromconsumption,   --RateFromconsumption=consumptionEntryFormForTrimsCost.Rate,--AmountFromconsumption=consumptionEntryFormForTrimsCost.Amount,      preCst.Fileno as FileNo,    preCst.internalRef as InternalRef ,    ItemGroups.ItemGroupName as  TrimsGroupName,    UOMs.UomName,    ord.OrderAutoID as OrderAutoId,    trimCost.Id as TrimCostId,	UPPER(dbo.TRIM(cnsmptnTrims.GmtsColor)) as GmtsColor, 	UPPER(dbo.TRIM(cnsmptnTrims.Gmtssizes)) as Gmtssizes,	cnsmptnTrims.Id as ConsumptionId,	cnsmptnTrims.RefNo,	cnsmptnTrims.GmtsItemId,	cnsmptnTrims.PerAccessories,	sum(cnsmptnTrims.viewModelTotalQuantity) as SizeQnty,	cnsmptnTrims.mesurmentDescription                              --   (Select top(1) Color from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryColor, --(Select top(1) Dia from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryDia, --(Select top(1) ProcessLoss from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryProcess,    from ConsumptionEntryFormForTrimsCosts cnsmptnTrims  left join TrimCosts as trimCost  on cnsmptnTrims.TrimCostId=trimCost.Id left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID    left join ItemGroups on trimCost.GroupId=ItemGroups.Id	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id	left join UOMs on trimCost.ConsUOMId=UOMs.Id	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id  --  left join TrimsConsumtionTotalNAvgCaluculation() as trimsTotalNAvgCltn		-- on trimCost.Id=trimsTotalNAvgCltn.TrimsCostId 	 	    where   --trimCost.ConsUnitGmts>0 --  and cnsmtionEntryFrm.TotalQty>0 --and IsBookingComplete=0   preCst.PrecostingId is not null    and preCst.ApprovalStatus=2   and cnsmptnTrims.Id is not null	 	group by BuyerProfiles.ContactName,ord.BuyerID,ord.Style_Ref,ord.JobNo,	trimCost.Id,trimCost.PrecostingId,trimCost.GroupId,	cnsmptnTrims.Countries,trimCost.Description,trimCost.BrandSupRef,	trimCost.Remarks,trimCost.NominatedSuppId,SupplierProfiles.SupplierName,	trimCost.ConsUOMId,trimCost.ConsUnitGmts,trimCost.ApvlReq,trimCost.ImagePath,	preCst.Fileno,preCst.internalRef,ItemGroups.ItemGroupName,UOMs.UomName,	ord.OrderAutoID,trimCost.Id,trimCost.CountryId,cnsmptnTrims.Id,dbo.TRIM(cnsmptnTrims.GmtsColor) ,dbo.TRIM(cnsmptnTrims.Gmtssizes),GmtsItemId,RefNo,cnsmptnTrims.PerAccessories,cnsmptnTrims.mesurmentDescription	)as tbl   where     @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE OrderAutoId END  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE BuyerId END  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END  AND @groupId= CASE @groupId WHEN 0 THEN 0 ELSE GroupId END       End
GO
/****** Object:  StoredProcedure [dbo].[GetTrimsCostBudgetByJobLevelV2]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROC [dbo].[GetTrimsCostBudgetByJobLevelV2]
(
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int,
	@groupId int
	 
)
AS
BEGIN
 
 select BuyerName,BuyerId,StyleRef,JobName,OrderNo,PoDeptId,Id,PrecostingId,
GroupId,CountryId,CountryName,Description,BrandSupRef,Remarks,NominatedSuppId,
SupplierName,ConsUOMId,ConsUnitGmts,Rate,Amount,TotalQty,TotalAmount,ApvlReq,ImagePath,
 (dbo.IsTrimCostIdExist(TrimCostId)
 ) as 
 IsTrimBookingComplete,ConsFromconsumption,Ex,RateFromconsumption,FileNo,InternalRef,
TrimsGroupName,UomName,OrderAutoId,TrimCostId,GmtsColor,ItemColor,Gmtssizes,ConsumptionId,GmtsItemId
,RefNo,PerAccessories,
	SizeQnty,mesurmentDescription from(select * From ProcessTrimsCostForBkng(@jobNoId))as tbl
   where  
  -- @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE OrderAutoId END
--  AND 
  @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE BuyerId END
  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
 -- AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
  AND @groupId= CASE @groupId WHEN 0 THEN 0 ELSE GroupId END
     
  End
GO
/****** Object:  StoredProcedure [dbo].[GetTrimsCostBudgetByPoLevel]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetTrimsCostBudgetByPoLevel]
(
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int,
	@groupId int 
	 
)
AS
BEGIN
 
 select BuyerName,BuyerId,StyleRef,JobName,OrderNo,PoDeptId,Id,PrecostingId,
GroupId,CountryId,CountryName,Description,BrandSupRef,Remarks,NominatedSuppId,
SupplierName,ConsUOMId,ConsUnitGmts,Rate,Amount,TotalQty,TotalAmount,ApvlReq,ImagePath,
(dbo.IsConsumptionIdExist(ConsumptionId)) 
as IsTrimBookingComplete,ConsFromconsumption,Ex,RateFromconsumption,FileNo,InternalRef,
TrimsGroupName,UomName,OrderAutoId,TrimCostId,GmtsColor,Gmtssizes,ConsumptionId
from(select 
  BuyerProfiles.ContactName as  BuyerName,
 ord.BuyerID as BuyerId,
 ord.Style_Ref as StyleRef,
 ord.JobNo as JobName,
'' as OrderNo,
 cnsmptnTrims.PoNoId as PoDeptId,
 trimCost.Id,
  PrecostingId = trimCost.PrecostingId,
  trimCost.GroupId,
 trimCost.CountryId,
 country.Region_Name as CountryName,
  trimCost.Description,
 trimCost.BrandSupRef,
   trimCost.Remarks,
  trimCost.NominatedSuppId,
  SupplierProfiles.SupplierName,
    trimCost.ConsUOMId,
   trimCost.ConsUnitGmts,
   avg(cnsmptnTrims.Rate)as Rate,-- group Avg()
   avg(cnsmptnTrims.Amount) as Amount,-- group Avg()
   sum(cnsmptnTrims.TotalQty)  as TotalQty,-- group sum()
   sum(cnsmptnTrims.TotalAmount)as  TotalAmount,-- group sum()
   trimCost.ApvlReq,
     trimCost.ImagePath,                 
 --(select (CASE WHEN count(Id)


 -->0  THEN 1 ELSE 0 END)
--   from TrimsBookingItemDtlsChilds where TrimCostId=trimCost.Id
    --and OrderAutoId=ord.OrderAutoID and JobOrPoLevel='JOB level'
	--) 
  0	as IsTrimBookingComplete,
-- trimsTotalNAvgCltn.TotalTotalQty as ConsFromconsumption,
 sum(cnsmptnTrims.TotalQty) as ConsFromconsumption,--sum()
 --ConsFromconsumption=consumptionEntryFormForTrimsCost.Cons,
 
 0 as Ex,
 0 as RateFromconsumption,
-- 0 as RateFromconsumption,
   --RateFromconsumption=consumptionEntryFormForTrimsCost.Rate,
--AmountFromconsumption=consumptionEntryFormForTrimsCost.Amount,
  
 
   preCst.Fileno as FileNo,
    preCst.internalRef as InternalRef ,
    ItemGroups.ItemGroupName as  TrimsGroupName,
    UOMs.UomName,
    ord.OrderAutoID as OrderAutoId,
    trimCost.Id as TrimCostId,
	UPPER(dbo.TRIM(cnsmptnTrims.GmtsColor)) as GmtsColor, 
	UPPER(dbo.TRIM(cnsmptnTrims.Gmtssizes)) as Gmtssizes,
	cnsmptnTrims.Id as ConsumptionId
                             



 --   (Select top(1) Color from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryColor,
 --(Select top(1) Dia from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryDia,
 --(Select top(1) ProcessLoss from ConsumptionEntryForms where FabricCostId=trimCost.Id and GreyCons>0) as CnsmtnEntryProcess,
 

 
 from TrimCosts as trimCost 
 left join ConsumptionEntryFormForTrimsCosts cnsmptnTrims on cnsmptnTrims.TrimCostId=trimCost.Id
 left join PreCostings as preCst on trimCost.PreCostingId=preCst.PrecostingId
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
 -- left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
    left join ItemGroups on trimCost.GroupId=ItemGroups.Id
	left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id
	left join UOMs on trimCost.ConsUOMId=UOMs.Id
	left join TblRegionInfoes as country on trimCost.CountryId=country.RegionID
	left join SupplierProfiles on trimCost.NominatedSuppId=SupplierProfiles.Id
  --  left join TrimsConsumtionTotalNAvgCaluculation() as trimsTotalNAvgCltn
		-- on trimCost.Id=trimsTotalNAvgCltn.TrimsCostId 
	 
	  
  where 
  --trimCost.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
--and IsBookingComplete=0
    preCst.PrecostingId is not null  and preCst.ApprovalStatus=2
	--and preCst.PrecostingId=5019
	group by BuyerProfiles.ContactName,ord.BuyerID,ord.Style_Ref,ord.JobNo,
	trimCost.Id,trimCost.PrecostingId,trimCost.GroupId,
	country.Region_Name,trimCost.Description,trimCost.BrandSupRef,
	trimCost.Remarks,trimCost.NominatedSuppId,SupplierProfiles.SupplierName,
	trimCost.ConsUOMId,trimCost.ConsUnitGmts,trimCost.ApvlReq,trimCost.ImagePath,
	preCst.Fileno,preCst.internalRef,ItemGroups.ItemGroupName,UOMs.UomName,
	ord.OrderAutoID,trimCost.Id,trimCost.CountryId,cnsmptnTrims.Id,dbo.TRIM(cnsmptnTrims.GmtsColor)
 ,dbo.TRIM(cnsmptnTrims.Gmtssizes),cnsmptnTrims.PoNoId
	)as tbl
   where  
   @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE OrderAutoId END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE BuyerId END
  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
  AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
  AND @groupId= CASE @groupId WHEN 0 THEN 0 ELSE GroupId END
     
  End
GO
/****** Object:  StoredProcedure [dbo].[GetYarnConsOptimaizationStripeColor]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetYarnConsOptimaizationStripeColor](	@FabricId Int 	 )ASBEGIN   select yos.Id as Id,  yos.CompositionId,  yos.Percentage,  Yos.Cons,  sc.Id as StripeId,  sc.FabricCostId,  sc.FabricReqQty,  sc.StripColor,  sc.BodyColor from YarnConsOptimaizationStripeColor yos left  join StripColors sc on sc.Id=yos.StripeColorId  where   sc.FabricCostId=@FabricId     End
GO
/****** Object:  StoredProcedure [dbo].[GetYarnCountDtermntnOrFabDesc]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[GetYarnCountDtermntnOrFabDesc](	@CmnCompanyId INT 	--@StyleRef nvarchar,	--@OrderId INT,	--@PoNo INT,	--@Buyer	INT	)ASBEGIN--DECLARE @stfWorker INT	--IF @StaffWorkBoth=1 	--SET @StyleRef='TestStyle_001'	--IF @StaffWorkBoth=2 SET @stfWorker=1	--IF @StaffWorkBoth=3 SET @stfWorker=3	--IF @DepartmentId = 0 SET @DepartmentId = NULL 	--IF @EmployeeId = 0 SET @EmployeeId = NULL 	--IF @OfficeId = 0 SET @OfficeId = NULL	--IF @SecId IS NULL SET @SecId = 0	--IF @FloorId IS NULL SET @FloorId = 0	--IF @DegId IS NULL SET @DegId=0		--Declare @val Varchar(MAX) select  ROW_NUMBER() Over (Order by YD.Construction) as serialNo,  YD.Id,  YD.FabricNature,  YD.Construction,   YD.ColorRange,  YD.GSM,  YD.Status,  YD.StitchLength,  YD.ProcessLoss,  YD.SequenceNo,   cc.CountDeterminationId,  cc.Composition,  YD.Construction+cc.Composition as ConstructionPlusComposition    from YarnCountDeterminations as YD cross join   CountComposition() cc   order by   YD.ConstructionEND
GO
/****** Object:  StoredProcedure [dbo].[GetYarnDyeingWorkOrderByProcessId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select * from TblInitialOrders where OrderAutoID=12039 --select * from PreCostings where OrderId=12039 -- DROP PROCEDURE GetYarnDyeingWorkOrderByProcess CREATE PROC [dbo].[GetYarnDyeingWorkOrderByProcessId](	@BuyerId Int,	@jobNoId Int,	@poNoId Int,	@styleRef varchar,	@YearId Int ,	@ProcessId Int,	@PFBId Int,	@YPOBookingId Int	 )ASBEGIN  with cte as (select ywf.*                          from ProcessYarnInfoByPrecostingIdAfterBkngWithFabric(@jobNoId,(select PrecostingId from PreCostings where OrderId=@jobNoId),0)  ywf                           where exists (select 1 from			               YarnPurchaseOrderDetails yd								  where  yd.OrderAutoId=ywf.OrderAutoId   								   and  yd.YarnCountId=ywf.CountId 								   and  yd.CompositionId=ywf.Comp1Id								   and  yd.percentage=ywf.percentage								   --and  yd.Color=ywf.GmtsColor								   )			   )   select 	 BuyerProfiles.ContactName,	 ord.BuyerID as BuyerId,	 ord.Style_Ref as StyleRef,	 ord.JobNo ,	 preCst.Fileno,	 ord.OrderAutoID ,	 preCst.PrecostingId,	 0 as PoNoId,	 '' as Remarks,	 GarmentsItemEntries.ItemName as GmtsItemName, 	 fabCost.GmtsItemId as GmtsItemId,	 fabCost.Id as FabricCostId,	 fabCost.BodyPartId ,	 BodyPartEntries.BodyPartFullName as BodyPartName,	 fabCost.BodyPartTypeId,	 BodyPartTypes.BodyPartTypeName,	 fabCost.FabNatureId,	 FabricNatures.FabricNatureName,	 fabCost.ColorTypeId,	 ColorTypes.ColorTypeName,	 fabCost.FabricDesPreCostId,	 fabCost.FabricDescription,	 fabCost.FabricSourceId,	 StaticFabricSource.FabricSourceName,	 fabCost.NominatedSuppId,	 '' as NominatedSupplier,	 fabCost.WidthDiaType,	 fabCost.GsmWeight,	 fabCost.ColorSizeSensitive,	 fabCost.ConsumptionBasis,	 fabCost.Uom,	 fabCost.AvgGreyCons,	 fabCost.Rate,	 fabCost.Amount,	 fabCost.TotalQty,	 fabCost.TotalAmount,	 fabCost.SuplierId,     fabCost.Amount as CnsmtnEntryAmount,    fabCost.TotalAmount as CnsmtnEntryTotalAmount,    cte.ItemColor   as CnsmtnEntryColor,	''  as GmtsSizes,	''  as ItemSizes,    '' as   CnsmtnEntryDia,    0  as CnsmtnEntryProcess,    0 as TotalGreyConsAvg ,    0 as TotalTotalQty,   cte.GmtsColor as GmtsColor,   cte.ItemColor as FabricColor,   ProductionProcesses.ProductionProcessName,   0 as ConversionId,   ProcessId=cte.ProceessId,   0 as ProcessLoss,   0 as ConversionReqQty,   0 as ConvrsnAvgReqQty,   0 as ConvrsnChargeUnit,   0 as ConversionAmount,   cte.CountId,   cte.CountName as CountName,   cte.Comp1Id,   Compositions.CompositionName,   cte.percentage,   cte.GmtsColor as yarnColor,   cte.TypeId,   Typpes.TypeName,   cte.ConsQnty as YarnConsQnty,   0 as yarnSupplierId,   '' as yarnSupplier,   cte.Rate as yarnRate,   (cte.Rate*cte.ConsQnty) as yarnAmount,   strpClr.Id as strpClrId,   strpClr.StripColor,   strpClr.Measurement as StrpMeasurment,   strpClr.Uom as StrpUom,   strpClr.TotalFeeder as StrpTotalFeeder,   strpClr.FabricReqQty as StrpFabricReqQty,   strpClr.BodyColor as StrpBodyColor,    cte.Quantity as yrnBkngWoQuantity,    ypo.id as  ypoId,    ypo.EntryDate as  YpoEntryDate,    ypo.WoNumber as  ypoWoNumber,    pfb.BookingNo as PfbBookingNo,    pfb.Id as PfbBookingId,    pfb.YearId as PfbYearId,    0 as pfbChldWoQnty,    0 as ServiceBookingStatus,	cte.RefNo as RefNo,	0 as cnsmtnId   from  cte     left join YarnPurchaseOrders ypo on ypo.id=(select top(1) YarnPurchaseOrderId from    YarnPurchaseOrderDetails where OrderAutoId=cte.OrderAutoId)   left join FabricCosts as fabCost on  fabCost.Id=cte.FabricCostId    left join PreCostings as preCst on fabCost.PreCostingId=preCst.PrecostingId   left join PartialFabricBookings pfb on pfb.Id=cte.pfbMasterId   left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID   left join   StripColors strpClr on strpClr.FabricCostId=-1   left join ProductionProcesses on ProductionProcesses.Id=cte.ProceessId   left join GarmentsItemEntries on fabCost.GmtsItemId=GarmentsItemEntries.Id   left join BodyPartEntries on fabCost.BodyPartId=BodyPartEntries.Id   left join BodyPartTypes on fabCost.BodyPartTypeId=BodyPartTypes.Id   left join BuyerProfiles on ord.BuyerID=BuyerProfiles.Id   left join ColorTypes on ColorTypes.Id=fabCost.ColorTypeId   left join Compositions on Compositions.Id =cte.Comp1Id   left join Typpes on Typpes.Id =cte.TypeId   left join FabricNatures on FabricNatures.Id=fabCost.FabNatureId   left join StaticFabricSource on StaticFabricSource.Id=fabCost.FabricSourceId		   where    preCst.PrecostingId is not null   and preCst.ApprovalStatus=2    and @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END   and @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END   and @ProcessId= CASE @ProcessId WHEN 0 THEN 0 ELSE cte.ProceessId END    and @PFBId= CASE @PFBId WHEN 0 THEN 0 ELSE pfb.Id END    and @YPOBookingId= CASE @YPOBookingId WHEN 0 THEN 0 ELSE ypo.id END   End
GO
/****** Object:  StoredProcedure [dbo].[GetYarnPurchaseOrderDetails]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE PROC [dbo].[GetYarnPurchaseOrderDetails](	  	@YPOBookingId Int  )ASBEGIN  select ypd.*,yo.WoNumber,yo.TargetDeliveryDate,tps.TypeName,
  yrnCunt.Name as YarnCount,compstion.CompositionName,um.UomName from YarnPurchaseOrderDetails ypd left join YarnPurchaseOrders yo
  on ypd.YarnPurchaseOrderId=yo.Id  left join Typpes as tps on  tps.Id=ypd.TypeId left join YarnCounts as yrnCunt on  yrnCunt.Id=ypd.YarnCountId left join Compositions as compstion on  compstion.Id=ypd.CompositionId  left join UOMs as um on um.Id=ypd.UomId  where       @YPOBookingId= CASE @YPOBookingId WHEN 0 THEN 0 ELSE yo.Id END  End 
GO
/****** Object:  StoredProcedure [dbo].[GetYarnPurchaseRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   create PROC [dbo].[GetYarnPurchaseRpt](	@BuyerId Int,	@jobNoId Int,	@styleRef varchar,	@YearId Int ,	@YPOBookingId Int	 )ASBEGIN   select  yod.*,yo.WoNumber,ic.ItemCategoryName,splr.SupplierName,yo.WoDate,  dm.DiscountMethodName as CurrencyName,yo.TargetDeliveryDate,tps.TypeName,yrnCunt.Name as CountName,  compstion.CompositionName,um.UomName     from YarnPurchaseOrders yo  left join YarnPurchaseOrderDetails yod on yod.YarnPurchaseOrderId=yo.Id  left join  TblInitialOrders as ord  on yod.OrderAutoId=ord.OrderAutoID  left join  ItemCategories ic   on ic.Id=yo.ItemCategoryId  	left join SupplierProfiles splr on splr.Id=yo.SupplierProfileId		left join DiscountMethods dm on dm.Id=yo.CurrencyId		 left join Typpes as tps on tps.Id=yod.TypeId left join YarnCounts as yrnCunt on yrnCunt.Id=yod.YarnCountId left join Compositions as compstion on compstion.Id=yod.CompositionId left join UOMs um on um.Id=yod.UomId  where  @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END and @YPOBookingId= CASE @YPOBookingId WHEN 0 THEN 0 ELSE yo.Id END  End 
GO
/****** Object:  StoredProcedure [dbo].[ImportFileNumbers]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create proc [dbo].[ImportFileNumbers]as begin with BTBORMargin as(   select Id,value as PiMasterId from BTBORMarginLCs cross apply    string_split(PiMasterId,',') group by Id,PiMasterId,value),  btbAndPiConnectivity as(  select b.Id, b.PiMasterId,pi.PiNo,(case when pi.PiBasis='Work Order Based' then fl.Fileno  else (SELECT LTRIM(RTRIM(pi.InternalFileNo)))end)FileNo from BTBORMargin b left join  ProFormaInvoiceV2PIDetails pi on pi.Id=b.PiMasterIdleft join (select * from PiAndWorkOrderConnectivityFunction())fl on fl.PiId=b.PiMasterId)--select * from BTBORMarginselect ''BtbIds,FileNo from btbAndPiConnectivity where FileNo is not null and FileNo <>'' group by FileNoend
GO
/****** Object:  StoredProcedure [dbo].[isFabricBookingDiaOrFinsConsWiseOrNot]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[isFabricBookingDiaOrFinsConsWiseOrNot](    @BookingId Int 	 )ASBEGIN   select  bookinChild.fabCnsDia,  fabConsumtion.FinishCons  from PartialFabricBookings as booking  left join     PartialFabricBookingItemDtlsChilds bookinChild on bookinChild.PartialFabricBookingMasterId= booking.Id  left join ConsumptionEntryForms fabConsumtion on fabConsumtion.Id=bookinChild.fabCnsId    where  booking.TrimsDyingToMatch='JOB level' and        bookinChild.PrecostingId is not null 	and  bookinChild.PartialFabricBookingMasterId=@BookingId 	and fabConsumtion.FinishCons>0 and fabConsumtion.FinishCons is not null	and  bookinChild.fabCnsDia!='' and  bookinChild.fabCnsDia is not null group by bookinChild.fabCnsDia,  fabConsumtion.FinishCons  End 
GO
/****** Object:  StoredProcedure [dbo].[PartialFabBkngHelprForSrcngOrderId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PartialFabBkngHelprForSrcngOrderId]
(
 @fabricBookingMasterId int
	 
)
AS
BEGIN
SELECT DISTINCT pbd.PreCostingId,preCst.OrderId
FROM PartialFabricBookingItemDtlsChilds pbd left join PreCostings  preCst on preCst.PrecostingId=pbd.PreCostingId
WHERE pbd.PartialFabricBookingMasterId=@fabricBookingMasterId;
End
GO
/****** Object:  StoredProcedure [dbo].[PiInfoGetByBtbId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 CREATE PROC [dbo].[PiInfoGetByBtbId](	@BtbId INT  )ASBEGINSET NOCOUNT ON;with cte as (select pfi.*,cmp.Company_Name,supp.SupplierName,
ic.ItemCategoryName,DiscountMethods.DiscountMethodName as CurrencyName,
x.Upcharge,
x.Discount,
(x.Amount+x.Upcharge)-x.Discount as NetTotal,
x.Amount as Total 
from ProFormaInvoiceV2PIDetails pfi
left join  DiscountMethods on DiscountMethods.Id=pfi.CurrencyId
left join   TblCompanyInfoes cmp on cmp.CompID=pfi.ImporterId
left join   SupplierProfiles supp on supp.Id=pfi.SupplierId
left join ItemCategories ic on ic.Id=pfi.ItemCategoryId
left join (select PiMasterId,SUM(Amount) as Amount,AVG(Upcharge) 
as Upcharge,Avg(Discount) as Discount from PiEntryFromWo  group by PiMasterId ) x on x.PiMasterId=pfi.Id
where pfi.Id  in (SELECT value  FROM STRING_SPLIT((select top 1 PiMasterId from BTBORMarginLCs where Id=@BtbId),','))
),
piAcceptces as (select PiMasterId,SUM(CurrAcptncValue) as AccptncVlue from PiAcceptances group by PiMasterId)
 

 
select cte.*,cte.NetTotal-pia.AccptncVlue as Balance from cte left join piAcceptces pia on pia.PiMasterId=cte.Id
  
END	
GO
/****** Object:  StoredProcedure [dbo].[PreCostingRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[PreCostingRpt]
(
	@CmnCompanyId INT,
	@StyleRef nvarchar,
	@OrderId INT,
	@PoNo INT,
	@Buyer	INT
	)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 
	--SET @StyleRef='TestStyle_001'
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	
	Declare @val Varchar(MAX)

 select 
-- TblPodetailsInfroes.InitialOrderID,
-- TblPodetailsInfroes.PO_No,
 PreCstng.PrecostingId,
 cstCmpRslt.PricePcs,
 PreCstng.OrderId,
PreCstng.BuyerID,
PreCstng.jobQty,
BuyerProfiles.ContactName,
PreCstng.StyleRef,
TblInitialOrders.JobNo,  
--TblPodetailsInfroes.Org_Shipment_Date,
(PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then
 ( select count(id)
 from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end)) as QtyPCS,
(PreCstng.jobQty*cstCmpRslt.PricePcs) as TotalAmount,
(CAST(PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then
 ( select count(id)
 from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end) AS decimal(10,0))/ 12) as QtyDzn,
cstCmpRslt.Freight,
cstCmpRslt.FabricCost,
cstCmpRslt.TrimsCost,
cstCmpRslt.EmbelCost,
cstCmpRslt.CommlCost,
cstCmpRslt.CMCost,
cstCmpRslt.Commission,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.FabricCost,cstCmpRslt.TotalCost) as FabricCostPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.TrimsCost,cstCmpRslt.TotalCost) as TrimCostPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.EmbelCost,cstCmpRslt.TotalCost) as EmbelCostPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.GmtsCost,cstCmpRslt.TotalCost) as GmtsPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.CommlCost,cstCmpRslt.TotalCost) as CommlCostPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.CMCost,cstCmpRslt.TotalCost) as CMCostPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.Commission,cstCmpRslt.TotalCost) as CommissionCostPercentage,
dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.Freight,cstCmpRslt.TotalCost) as FreightCostPercentage,
-- poinfrosTemp.PoNumbers as poNumbers,
 --poinfrosTemp.ShipmentDates as orgShipmentDates,
 (select top(1 ) PoNumbers from GetPoNoNameInStringByOrderId(PreCstng.OrderId)) as PoNumbers,
 (select  Org_Shipment_Dates   from GetOrg_Shipment_DateInStringByOrderId(PreCstng.OrderId)) as ShipmentDates,
 (select * from GetItemNameInStringByOrderId(PreCstng.OrderId)) as ItemNames

from PreCostings as PreCstng 
left join BuyerProfiles on PreCstng.BuyerID=BuyerProfiles.Id
left join   TblInitialOrders  on PreCstng.OrderId=TblInitialOrders.OrderAutoID 
--left join GetPoNoNameInStringByOrderId(PreCstng.OrderId) as poinfrosTemp on PreCstng.OrderId=poinfrosTemp.OrderId
--left join TblPodetailsInfroes  on PreCstng.OrderId=TblPodetailsInfroes.InitialOrderID 
--left join ItemDetailsOrderEntries  on PreCstng.OrderId=ItemDetailsOrderEntries.order_entry_id 
--left join GarmentsItemEntries  on ItemDetailsOrderEntries.item=GarmentsItemEntries.Id
left join CostComponentHorizontalResult() as cstCmpRslt on PreCstng.PrecostingId=cstCmpRslt.PrecostingId
--where PreCstng.StyleRef='KB PYJ 49' or TblInitialOrders.JobNo='MKL-22-07'
--where  TblInitialOrders.OrderAutoID=1005 group by TblInitialOrders.OrderAutoID
where  TblInitialOrders.OrderAutoID=@OrderId 
END
GO
/****** Object:  StoredProcedure [dbo].[processInvcForbillingById]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[processInvcForbillingById](@invoiceId int)as
begin
 with cte as(
 select ExportInformationId,
 STRING_AGG (OrderNo, ',') as OrderNumbers,
 STRING_AGG (JobNo, ',') as JobNos,
 STRING_AGG (StyleRef, ',') as StyleRefs,
 sum(CurrInvoiceQnty) as CurrInvoiceQnty,
 sum(CurrInvoiceValue) as CurrInvoiceValue,
 max(ShipmentDate) as ShipmentDate
 from ExportInformationDetails group by ExportInformationId)
 select cte.*,inv.UseLcOrSC,inv.LcOrSCNo,inv.InvoiceDate,inv.ExpformNo,inv.LienBankId,
 subInv.InvoiceValue,subInv.NetInvoiceValue
 from  ExportInvoiceUpdates inv  left join cte on cte.ExportInformationId=inv.Id
        left join ExportInformationDetailsSubs subInv on subInv.ExportInvoiceId=inv.Id
		where inv.id=@invoiceId

end
GO
/****** Object:  StoredProcedure [dbo].[ServicebkngAopBookingQuantity]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   create PROC [dbo].[ServicebkngAopBookingQuantity](	@ServiceBookingId INT )ASBEGIN  select sbchildDtls.OrderAutoID,[dbo].[GetPoQuantityByOrderId](sbchildDtls.OrderAutoID) as OrderQnty  from ServiceBookingAllChildDetails sbchildDtls   where sbchildDtls.ProcessId=20 and --process value 20 means it is aop service booking   @ServiceBookingId= CASE @ServiceBookingId WHEN 0 THEN 0 ELSE sbchildDtls.MasterId END   group by sbchildDtls.OrderAutoID       END
GO
/****** Object:  StoredProcedure [dbo].[ServicebkngAopRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   CREATE PROC [dbo].[ServicebkngAopRpt](	@ServiceBookingId INT,	@FabricBookingId INT,	@OrderAutoId INT,	@StyleRef nvarchar(max),	@RefNo nvarchar(max),	@PoId Int	 )ASBEGIN select sbchildDtls.*,sbmDtls.BookingDate,sbmDtls.BookingNo as AopBookinNo,bp.ContactName as Buyer,(select top(1) PoNumbers from GetPoNoNameInStringByOrderId(sbchildDtls.OrderAutoID)) as PoNumbers  from ServiceBookingAllChildDetails sbchildDtls left join ServiceBookingAllMasterDtls sbmDtls on sbmDtls.Id=sbchildDtls.MasterId left join BuyerProfiles bp on bp.Id=sbchildDtls.BuyerId    where sbchildDtls.ProcessId=20 and --process value 20 means it is aop service booking   @ServiceBookingId= CASE @ServiceBookingId WHEN 0 THEN 0 ELSE sbchildDtls.MasterId END and  @FabricBookingId= CASE @FabricBookingId WHEN 0 THEN 0 ELSE sbchildDtls.PfBookingId END and   @OrderAutoId= CASE @OrderAutoId WHEN 0 THEN 0 ELSE sbchildDtls.OrderAutoID END and     @StyleRef= CASE @StyleRef WHEN '' THEN '' ELSE sbchildDtls.StyleRef END and 	@RefNo= CASE @RefNo WHEN '' THEN '' ELSE sbchildDtls.RefNo END and 	@PoId= CASE @PoId WHEN 0 THEN 0 ELSE @PoId END   END
GO
/****** Object:  StoredProcedure [dbo].[TopChartPreCostingRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[TopChartPreCostingRpt]
( 
	@OrderId INT 
	)
AS

BEGIN
 
select TblInitialOrders.JobNo,-- TblPodetailsInfroes.PO_No, PreCstng.PrecostingId, cstCmpRslt.PricePcs, PreCstng.OrderId,PreCstng.BuyerID,PreCstng.jobQty,BuyerProfiles.ContactName,PreCstng.StyleRef, --TblPodetailsInfroes.Org_Shipment_Date,(PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end)) as QtyPCS,(PreCstng.jobQty*cstCmpRslt.PricePcs) as TotalAmount,(CAST(PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end) AS decimal(10,0))/ 12) as QtyDzn,cstCmpRslt.Freight,cstCmpRslt.FabricCost,cstCmpRslt.TrimsCost,cstCmpRslt.EmbelCost,cstCmpRslt.CommlCost,(cstCmpRslt.CMCost*PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end))/12 as CMCost,cstCmpRslt.Commission,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.FabricCost,cstCmpRslt.TotalCost) as FabricCostPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.TrimsCost,cstCmpRslt.TotalCost) as TrimCostPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.EmbelCost,cstCmpRslt.TotalCost) as EmbelCostPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.GmtsCost,cstCmpRslt.TotalCost) as GmtsPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.CommlCost,cstCmpRslt.TotalCost) as CommlCostPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.CMCost,cstCmpRslt.TotalCost) as CMCostPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.Commission,cstCmpRslt.TotalCost) as CommissionCostPercentage,dbo.PrecstingBudgetPriceIndivitualPercetage(cstCmpRslt.Freight,cstCmpRslt.TotalCost) as FreightCostPercentage,-- poinfrosTemp.PoNumbers as poNumbers, --poinfrosTemp.ShipmentDates as orgShipmentDates, (select top(1 ) PoNumbers from GetPoNoNameInStringByOrderId(PreCstng.OrderId)) as PoNumbers, (select  Org_Shipment_Dates   from GetOrg_Shipment_DateInStringByOrderId(PreCstng.OrderId)) as ShipmentDates, (select * from GetItemNameInStringByOrderId(PreCstng.OrderId)) as ItemNames, fabricPvotTbl.Tamount WovenOrPurchaseFabricCost, (convrsnPvotTbl.[2]*PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end))/12 as Knitting,( convrsnPvotTbl.[3]*PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end))/12 as FabricDyeing, (convrsnPvotTbl.[21]*PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end))/12 as YarnDyeing, (convrsnPvotTbl.[20]*PreCstng.jobQty*(case when TblInitialOrders.Order_Uom_ID=32 then ( select count(id) from ItemDetailsOrderEntries where order_entry_id=PreCstng.OrderId) else 1 end))/12 as AllOverPrinting, (case when washPvotTbl.TotalAmount is not null then washPvotTbl.TotalAmount else 0 end) as WashCost, trimsPvotTbl.Tamount as AccessoriesOrTrimsAmount, (case when embelPvotTbl.Printing is not null then embelPvotTbl.Printing else 0 end) as Printing , (case when  embelPvotTbl.Embroidery is not null then embelPvotTbl.Embroidery else 0 end) as Embroidery,(case when  yCwithOutlacra.TotalAmount is not null then  yCwithOutlacra.TotalAmount else 0 end) as yarnPrice,(case when  yCwithlacra.TotalAmount is not null then yCwithlacra.TotalAmount else 0 end) as yarnLacra, (cstCmpRslt.LabTest+cstCmpRslt.CurrierCost) as labtestNCurrierCostfrom PreCostings as PreCstng left join BuyerProfiles on PreCstng.BuyerID=BuyerProfiles.Idleft join   TblInitialOrders  on PreCstng.OrderId=TblInitialOrders.OrderAutoID left join CostComponentHorizontalResult() as cstCmpRslt on PreCstng.PrecostingId=cstCmpRslt.PrecostingIdleft join FabricCostPivotTbl() fabricPvotTbl on fabricPvotTbl.PrecostingId=PreCstng.PrecostingIdleft join ConversionCostPivotTbl() convrsnPvotTbl on convrsnPvotTbl.PrecostingId=PreCstng.PrecostingIdleft join WashCostPivotTblv2() washPvotTbl on washPvotTbl.PrecostingId=PreCstng.PrecostingIdleft join trimsCostPivotTblV2() trimsPvotTbl on trimsPvotTbl.PrecostingId=PreCstng.PrecostingIdleft join EmbelCostPivotTbl() embelPvotTbl on embelPvotTbl.PrecostingId=PreCstng.PrecostingIdleft join YarnCostWithOutLacra() yCwithOutlacra on yCwithOutlacra.PrecostingId=PreCstng.PrecostingIdleft join YarnCostWithLacra() yCwithlacra on yCwithlacra.PrecostingId=PreCstng.PrecostingId
--where  TblInitialOrders.OrderAutoID=@OrderId 
END
GO
/****** Object:  StoredProcedure [dbo].[TrimCostsRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[TrimCostsRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@InitialOrderId int,
	@JobNo Varchar,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
 ItmGrp.Id,
 ItmGrp.ItemGroupName,
 uom.Id as UomId,
 uom.UomName,
 (TrmCst.ConsUnitGmts*TrmCst.Rate) as Amount,
 TrmCst.Description,
 TrmCst.Rate,
(TrmCst.TotalQty*TrmCst.Rate) as TotalAmount,
  TrmCst.TotalQty,
   TrmCst.ConsUnitGmts
from TrimCosts as TrmCst
left join ItemGroups as ItmGrp on TrmCst.GroupId=ItmGrp.Id
left join UOMs as uom on TrmCst.ConsUOMId=uom.Id
left join PreCostings as prcStng on prcStng.PrecostingId=TrmCst.PrecostingId 
 where prcStng.OrderId=@InitialOrderId 
END
GO
/****** Object:  StoredProcedure [dbo].[TrimsBookingJobWiseRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[TrimsBookingJobWiseRpt]
(
   @BookingId Int,
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int 
	 
)
AS
BEGIN
  
  select 
  supPro.SupplierName,
 ord.JobNo,
 ord.Style_Ref,
 ord.Repeat_No_Job,
  BuyerWiesSeasons.SeasonName,
 BuyerProfiles.ContactName,
 trims.Level,
 trims.BookingNo,
 trims.BookingDate,
 trims.DeliveryDate,
 dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as PoQnty,
 currency.DiscountMethodName as currencyName,
  userDlngMrcnd.FullName as DealingMarchand,
 trims.PayMode,
  trims.Remarks,
   trims.Source,
    trims.Attention,
  trimsChild.TrimCostId,
  trimsChild.ReqQnty,
  trimsChild.Woq,
  trimsChild.Rate,
  trimsChild.Amount,
 trimsChild.BrandSup,
 trimsChild.TrimsGroup,
  trimsChild.Description,
(case when trimsChild.OrdNo='' then (select top(1 ) PoNumbers from 
GetPoNoNameInStringByOrderId(preCst.OrderId)) else  trimsChild.OrdNo  end )as PoNo,
 --clrNSize.Color as GmtsColor,
 --clrNSize.Size as Gmtssizes,
 --clrNSize.ItemId,
-- embeCnsmtion.PoNo,
'' as GmtsColor,
'' as Gmtssizes,
'' as ItemSizes,
 preCst.PrecostingId,
  preCst.internalRef,
  preCst.Fileno,
  UOMs.UomName,
  cnsmtion.Id as cnsmtionId,
  cnsmtion.RefNo,
  
(select top(1) BookingQnty from  getTrimsBookingQnty(trims.Id)) as BookingQnty

 --clrSensitive.ContrastColor
 --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id)

  from MultipleJobWiseTrimsBookingV2 as trims
  
 left join  TrimsBookingItemDtlsChilds trimsChild on trimsChild.TrimsBookingMasterId= trims.Id
  left join ConsumptionEntryFormForTrimsCosts as cnsmtion on cnsmtion.Id=trimsChild.ConsumptionId
  left join TrimCosts as trimsCost on trimsChild.TrimCostId=trimsCost.Id
 left join PreCostings as preCst on preCst.PrecostingId=trimsCost.PrecostingId 
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
-- left join SupplierProfiles on trimsCost.s=SupplierProfiles.Id
  --left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 --   left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
	--left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
	left join BuyerProfiles on trims.BuyerNameId=BuyerProfiles.Id
	left join DiscountMethods as currency on currency.Id=trims.CurrencyId
	left join UOMs on ord.Order_Uom_ID=UOMs.Id 
   left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id
   -- left join UserMappings on UserMappings.Id=ord.Dealing_Merchant_ID
	left join SupplierProfiles as supPro on trims.SupplierNameId=supPro.Id
	left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
 -- left join  ConsumptionEntryFormForTrimsCosts trimsCnsmtn on trimsCnsmtn.TrimCostId=trimsChild.TrimCostId
--	left join FabricCosts fabCst on fabCst.PreCostingId=preCst.PrecostingId 
	--and fabCst.BodyPartId=trimsChild.BodyPartId   
	--left join (select * from GetItemNColorNSizeByPoId()) as clrNSize on clrNSize.PoId=trimsChild.PoDeptId
   -- left join FabricColorSensitivities clrSensitive on clrSensitive.FabricId=fabCst.Id

	--left join TblRegionInfoes as country on trims.CountryId=country.RegionID
	
    
	 
	  
  where 
  --trims.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
 -- IsTrimBookingComplete=0 and
 trims.Level='JOB level'and 
    preCst.PrecostingId is not null 
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
   AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE trims.Id END
  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
       
  End
GO
/****** Object:  StoredProcedure [dbo].[TrimsBookingPoWiseRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROC [dbo].[TrimsBookingPoWiseRpt]
(
    @BookingId Int,
	@BuyerId Int,
	@jobNoId Int,
	@poNoId Int,
	@styleRef varchar,
	@YearId Int 
	 
)
AS
BEGIN
  
   select 
   supPro.SupplierName,
 ord.JobNo,
 ord.Style_Ref,
 ord.Repeat_No_Job,
  BuyerWiesSeasons.SeasonName,
 BuyerProfiles.ContactName,
 trims.Level,
 trims.BookingNo,
 trims.BookingDate,
 trims.DeliveryDate,
 dbo.GetPoQuantityByOrderId(ord.OrderAutoID) as PoQnty,
 currency.DiscountMethodName as currencyName,
 userDlngMrcnd.FullName  as DealingMarchand,
 trims.PayMode,
  trims.Remarks,
   trims.Source,
    trims.Attention,
  trimsChild.TrimCostId,
  trimsChild.ReqQnty,
  trimsChild.Woq,
  trimsChild.Rate,
  trimsChild.Amount,
 trimsChild.BrandSup,
 trimsChild.TrimsGroup,
  trimsChild.Description,
(case when trimsChild.OrdNo='' then (select top(1 ) PoNumbers from 
GetPoNoNameInStringByOrderId(preCst.OrderId)) else  trimsChild.OrdNo  end )as PoNo,
 --clrNSize.Color as GmtsColor,
 --clrNSize.Size as Gmtssizes,
 --clrNSize.ItemId,
-- embeCnsmtion.PoNo,
'' as GmtsColor,
'' as Gmtssizes,
'' as ItemSizes,
 preCst.PrecostingId,
  preCst.internalRef,
  preCst.Fileno,
  UOMs.UomName ,
  (select top(1) BookingQnty from  getTrimsBookingQnty(trims.Id)) as BookingQnty
 --clrSensitive.ContrastColor
 --(select ContrastColor  from FabricColorSensitivities where FabricId=fabCst.Id)

    from MultipleJobWiseTrimsBookingV2 as trims 
 left join TrimsBookingItemDtlsChilds trimsChild on trimsChild.TrimsBookingMasterId= trims.Id
  left join TrimCosts as trimsCost on trimsChild.TrimCostId=trimsCost.Id
 left join PreCostings as preCst on preCst.PrecostingId=trimsCost.PrecostingId 
 left join  TblInitialOrders as ord  on preCst.OrderId=ord.OrderAutoID
-- left join SupplierProfiles on trimsCost.s=SupplierProfiles.Id
  --left join TblPodetailsInfroes poDtls on ord.OrderAutoID=poDtls.InitialOrderID
 --   left join EmbellishmentTypes on embel.EmbelTypeId=EmbellishmentTypes.Id
	--left join BodyPartEntries on embel.BodyPartId=BodyPartEntries.Id
	left join BuyerProfiles on trims.BuyerNameId=BuyerProfiles.Id
	left join DiscountMethods as currency on currency.Id=trims.CurrencyId
	left join UOMs on ord.Order_Uom_ID=UOMs.Id 
   left join BuyerWiesSeasons on ord.Season_ID=BuyerWiesSeasons.Id
   left join TblUserInfoes userDlngMrcnd  on userDlngMrcnd.UserId=(select top(1) UserId  from UserMappings where Id=ord.Dealing_Merchant_ID)
   -- left join UserMappings on UserMappings.Id=ord.Dealing_Merchant_ID
	left join SupplierProfiles as supPro on trims.SupplierNameId=supPro.Id
 -- left join  ConsumptionEntryFormForTrimsCosts trimsCnsmtn on trimsCnsmtn.TrimCostId=trimsChild.TrimCostId
--	left join FabricCosts fabCst on fabCst.PreCostingId=preCst.PrecostingId 
	--and fabCst.BodyPartId=trimsChild.BodyPartId   
	--left join (select * from GetItemNColorNSizeByPoId()) as clrNSize on clrNSize.PoId=trimsChild.PoDeptId
   -- left join FabricColorSensitivities clrSensitive on clrSensitive.FabricId=fabCst.Id

	--left join TblRegionInfoes as country on trims.CountryId=country.RegionID
	
    
	 
	  
  where 
  --trims.ConsUnitGmts>0 
--  and cnsmtionEntryFrm.TotalQty>0 
 -- IsTrimBookingComplete=0 and
 trims.Level='PO level'and 
    preCst.PrecostingId is not null 
  AND @jobNoId= CASE @jobNoId WHEN 0 THEN 0 ELSE ord.OrderAutoID END
  AND @BuyerId= CASE @BuyerId WHEN 0 THEN 0 ELSE preCst.BuyerId END
  AND @BookingId= CASE @BookingId WHEN 0 THEN 0 ELSE trims.Id END
  --AND @YearId= CASE @YearId WHEN 0 THEN 0 ELSE OrderAutoID END
       
  End
GO
/****** Object:  StoredProcedure [dbo].[WashCostRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[WashCostRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
  typ.Id,
  wshCst.Name,
  wshCst.Amount,
  wshCst.Rate,
  wshCst.ConsOneDznGmts,
  typ.TypeName,
  TblReg.Region_Name
 from WashCosts as wshCst
left join Typpes as typ on wshCst.TypeId=typ.Id
left join TblRegionInfoes as TblReg on wshCst.CountryId=TblReg.RegionID
left join PreCostings as prcStng on prcStng.PrecostingId=wshCst.PrecostingId  

 where prcStng.OrderId=@InitialOrderId
END
GO
/****** Object:  StoredProcedure [dbo].[YarnCostsRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[YarnCostsRpt]
(
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
--DECLARE @stfWorker INT
	--IF @StaffWorkBoth=1 SET @stfWorker=2
	--IF @StaffWorkBoth=2 SET @stfWorker=1
	--IF @StaffWorkBoth=3 SET @stfWorker=3
	--IF @DepartmentId = 0 SET @DepartmentId = NULL 
	--IF @EmployeeId = 0 SET @EmployeeId = NULL 
	--IF @OfficeId = 0 SET @OfficeId = NULL
	--IF @SecId IS NULL SET @SecId = 0
	--IF @FloorId IS NULL SET @FloorId = 0
	--IF @DegId IS NULL SET @DegId=0	

 select 
 'Yarn Cost' as YarnCost,
 YrnCst.TypeId,
 tps.TypeName,
 yrnCunt.Name as CountName,
 compstion.CompositionName,
 YrnCst.ConsQnty,
 YrnCst.Rate*YrnCst.ConsQnty as Amount,
 YrnCst.percentage,
 --dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty) as TotalCons,
 cast((Cnsmtn.TotalCons*YrnCst.percentage)/100 AS  DECIMAL(18,4)) AS TotalCons,
  (YrnCst.Rate*cast((Cnsmtn.TotalCons) AS  DECIMAL(18,4))) as TotalAmount,
 YrnCst.Rate as AvgRate ,
  --yrnCunt.Name+ ' ' + compstion.CompositionName +' ' +tps.TypeName AS YarnDescription
  yrnCunt.Name+','+compstion.CompositionName as  YarnDescription

 --IF YrnCst.percentage=2
from YarnCosts as YrnCst
left join FabricCosts fc on fc.Id=YrnCst.FabricCostId
left join   PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId 
left join Typpes as tps on tps.Id=YrnCst.TypeId
left join  YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id
left join  Compositions as compstion on YrnCst.Comp1Id=compstion.Id
left join (select FabricCostId,sum((SizeQuantity/12)* GreyCons) TotalCons from ConsumptionEntryForms where FinishCons>0 
group by FabricCostId) Cnsmtn on Cnsmtn.FabricCostId=YrnCst.FabricCostId	

where prcCst.OrderId=@InitialOrderId
-- where prcCst.OrderId=21058
END

--select * from TblInitialOrders 
--select * from PreCostings where OrderId=21058
GO
/****** Object:  StoredProcedure [dbo].[YarnInformationByPrecostingIdOrOrdId]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE PROC [dbo].[YarnInformationByPrecostingIdOrOrdId](    @PrecostingId int,	@InitialOrderId int)ASBEGIN-- select * from StripColors where PrecostingId=18038--  select * from FabricColorSensitivities where PrecostingId=18038	select * from ( select YarnCost,PrecostingId,TypeId,TypeName,CountName,CompositionName,ConsQnty,Amount,	percentage, (case when ColorTypeId=9 then ((dbo.GetPercentage(TotalCons,percentage)*Measurement)/dbo.GetStripTotalMesurment(FabricCostId)) else dbo.GetPercentage(TotalCons,percentage) end )as TotalCons,	TotalAmount,AvgRate,YarnDescription,	 StripColor,	 BodyColor,  Measurement,--  strpClr. FabricReqQty,  Id, CountId, Comp1Id, pfbMasterId,ProceessId=21,ROW_NUMBER() over(partition by StripColor order by StripColor) as rn from (select  'Yarn Cost' as YarnCost, prcCst.PrecostingId, YrnCst.TypeId, tps.TypeName, yrnCunt.Name as CountName	, compstion.CompositionName, YrnCst.ConsQnty,--0 as ConsQnty,YrnCst.Rate*YrnCst.ConsQnty as Amount, --0 as Amount, YrnCst.percentage,  -- (fabCnsm.TotalFinishConsAvg/12)*( dbo.GetPoQuantityByOrderId(ord.OrderAutoID))  as TotalCons, --dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty) as TotalCons, --((( dbo.GetFabricConsumtionCstForYarnByFabricId(prcCst.PrecostingId,fabCst.Id)*100 )/(100-fabCnsm.TotalProcessLossAvg))) as TotalCons,  (case when fabCst.ColorTypeId <>9 then (dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) else 
   (dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty))   end)  as TotalCons,  (YrnCst.Rate*dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty)) as TotalAmount, --0  as TotalAmount ,  (YrnCst.Rate*YrnCst.ConsQnty)/(dbo.PrecstingtTotalConsCalculation(YrnCst.ConsQnty,prcCst.jobQty)) as AvgRate,-- 0 as AvgRate,  yrnCunt.Name+ ' ' + compstion.CompositionName +' ' +tps.TypeName AS YarnDescription,  YrnCst.FabricCostId, strpClr.BodyColor,  dbo.TRIM(strpClr.StripColor) as StripColor,  strpClr.Measurement,--  strpClr.strpClr.FabricReqQty,fabCst.ColorTypeId,0 AS Id,YrnCst.CountId,YrnCst.Comp1Id,pfbitemDtls.PartialFabricBookingMasterId as pfbMasterIdfrom PartialFabricBookingItemDtlsChilds pfbitemDtlsleft join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostIdleft join FabricCosts fabCst on fabCst.Id=YrnCst.FabricCostId--left join ConversionCostForPreCosts convCst on convCst.FabricCostId=fabCst.Idleft join   PreCostings as prcCst on prcCst.PrecostingId= YrnCst.precostingId  left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID --left join FabricConsumtionTotalNAvgCaluculation() as fabCnsm on fabCnsm.FabricCostId=YrnCst.FabricCostIdleft join Typpes as tps on tps.Id=YrnCst.TypeIdleft join YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Idleft join Compositions as compstion on YrnCst.Comp1Id=compstion.Idleft join   StripColors strpClr on strpClr.FabricCostId=fabCst.Id 	) as tbl 	where PrecostingId=18038	group by YarnCost,PrecostingId,TypeId,TypeName,CountName,CompositionName,ConsQnty,Amount,TotalAmount,	percentage,TotalCons ,AvgRate,YarnDescription,	BodyColor,	 StripColor,  Measurement,--  strpClr. FabricReqQty, ColorTypeId, FabricCostId, Id, CountId, Comp1Id, pfbMasterId) x where x.rn<2END 
GO
/****** Object:  StoredProcedure [dbo].[YarnInformationForFabBkngRptWithoutStripeColor]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
  
 CREATE PROC [dbo].[YarnInformationForFabBkngRptWithoutStripeColor]
(
    @FabricBookingId int, --required parameter FabricBookingId now precostingid
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate varchar,
	@FromDate varchar
)
AS
BEGIN
select
sum(TotalCons) as TotalCons ,
 CountName,
CompositionName,
max(ProcessLoss) as ProcessLoss 
 
 
  from (select 
  
 prcCst.PrecostingId,
  fabCst.ColorTypeId,
 
  pfbitemDtls.PartialFabricBookingMasterId,
--(case when YrnCst.isLoadFromStripeClr=0 then (dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) else 
--   (dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty))   end)  as TotalCons,
  --(dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty))  as TotalCons,

  case when YrnCst.isLoadFromStripeClr=0 then (((cnsmtn.SizeQuantity/12)*cnsmtn.GreyCons)* YrnCst.percentage)/100
       when YrnCst.isLoadFromStripeClr=1 then ((( cnsmtn.SizeQuantity/12)*strpClr.FabricReqQty)*YrnCst.percentage)/100
	   else 0
	   end TotalCons,
    
 --(((cnsmtn.SizeQuantity/12)*cnsmtn.GreyCons)* YrnCst.percentage)/100  as TotalCons,
  --(dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) as TotalCons,
 --cnsmtn.GreyCons,
 YrnCst.isLoadFromStripeClr,
 strpClr.StripColor,
yrnCunt.Name as CountName,
 
strpClr.BodyColor,
ct.ColorTypeName,
cnsmtn.ProcessLoss,
compstion.CompositionName,

--previous column
ord.JobNo ,
bdyprt.BodyPartFullName,
strpClr.Uom,
pfbitemDtls.GmtsColor,
pfbitemDtls.fabCnsColor as FabricColor,
strpClr.Measurement as StripeMeasurement,
strpClr.BodyMeasurement,
strpClr.YarnDyed,
YrnCst.Rate ,
YrnCst.Amount  


  from PartialFabricBookingItemDtlsChilds  pfbitemDtls
 left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostId
left join FabricCosts fabCst on fabCst.Id=pfbitemDtls.FabricCostId
left join   StripColors strpClr on strpClr.Id=YrnCst.StripeClrId 
 left join   PreCostings as prcCst on prcCst.PrecostingId= pfbitemDtls.precostingId 
 left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID
 left join Typpes as tps on tps.Id=YrnCst.TypeId
 left join YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id
 left join Compositions as compstion on YrnCst.Comp1Id=compstion.Id
 left join ColorTypes as ct on ct.Id=fabCst.ColorTypeId
 left join ConsumptionEntryForms cnsmtn on cnsmtn.Id=pfbitemDtls.fabCnsId
 left join BodyPartEntries as bdyprt  on fabCst.BodyPartId=bdyprt.Id

where 
pfbitemDtls.PartialFabricBookingMasterId=@FabricBookingId  
--pfbitemDtls.PartialFabricBookingMasterId=9016
--and YrnCst.isLoadFromStripeClr=0
--and 
--YrnCst.isLoadFromStripeClr=0
--prcCst.PrecostingId=@FabricBookingId
) 
as tbl group by 
CountName,
CompositionName
 order by CountName

--    select distinct PrecostingId,
--  ColorTypeId,
-- ColorTypeName,
-- PartialFabricBookingMasterId ,
--  sum(TotalCons) as TotalCons ,
 
--CountName,
--CompositionName,
--BodyColor,
--StripColor,
--avg(ProcessLoss) as ProcessLoss,
--JobNo ,
--BodyPartFullName,
--Uom,
--GmtsColor,
--FabricColor,
--StripeMeasurement,
--BodyMeasurement,
--YarnDyed,
--Rate,
-- sum(TotalCons)*Rate as Amount


 
--  from (select 
  
-- prcCst.PrecostingId,
--  fabCst.ColorTypeId,
 
--  pfbitemDtls.PartialFabricBookingMasterId,
----(case when YrnCst.isLoadFromStripeClr=0 then (dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) else 
----   (dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty))   end)  as TotalCons,
--  --(dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty))  as TotalCons,
--  ((cnsmtn.SizeQuantity/12)*YrnCst.ConsQnty)  as TotalCons,
--  --(dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) as TotalCons,
-- --cnsmtn.GreyCons,
-- YrnCst.isLoadFromStripeClr,
-- strpClr.StripColor,
--yrnCunt.Name as CountName,
--strpClr.BodyColor,
--ct.ColorTypeName,
--cnsmtn.ProcessLoss,
--compstion.CompositionName,

----previous column
--ord.JobNo ,
--bdyprt.BodyPartFullName,
--strpClr.Uom,
--pfbitemDtls.GmtsColor,
--pfbitemDtls.fabCnsColor as FabricColor,
--strpClr.Measurement as StripeMeasurement,
--strpClr.BodyMeasurement,
--strpClr.YarnDyed,
--YrnCst.Rate ,
--YrnCst.Amount


--  from PartialFabricBookingItemDtlsChilds  pfbitemDtls
-- left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostId
--left join FabricCosts fabCst on fabCst.Id=pfbitemDtls.FabricCostId
--left join   StripColors strpClr on strpClr.Id=YrnCst.StripeClrId 
-- left join   PreCostings as prcCst on prcCst.PrecostingId= pfbitemDtls.precostingId 
-- left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID
-- left join Typpes as tps on tps.Id=YrnCst.TypeId
-- left join YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id
-- left join Compositions as compstion on YrnCst.Comp1Id=compstion.Id
-- left join ColorTypes as ct on ct.Id=fabCst.ColorTypeId
-- left join ConsumptionEntryForms cnsmtn on cnsmtn.Id=pfbitemDtls.fabCnsId
-- left join BodyPartEntries as bdyprt  on fabCst.BodyPartId=bdyprt.Id

--where 
--pfbitemDtls.PartialFabricBookingMasterId=9016  
----and YrnCst.isLoadFromStripeClr=0
----and 
----YrnCst.isLoadFromStripeClr=0
----prcCst.PrecostingId=@FabricBookingId
--) 
--as tbl group by 
--PrecostingId,ColorTypeId,
--ColorTypeName,
--PartialFabricBookingMasterId ,
--CountName,
--CompositionName,
--BodyColor,
--StripColor ,
--JobNo,
--BodyPartFullName,
--Uom,
--GmtsColor,
--FabricColor,
--StripeMeasurement,
--BodyMeasurement,
--YarnDyed,
--Rate 
-- order by CountName,BodyColor,StripColor
END
GO
/****** Object:  StoredProcedure [dbo].[YarnInformationForFabBkngRptWithStripeColor]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   
 
 CREATE PROC [dbo].[YarnInformationForFabBkngRptWithStripeColor]
(
    @FabricBookingId int, --required parameter FabricBookingId now precostingid
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate varchar,
	@FromDate varchar
)
AS
BEGIN
   select PrecostingId,
  ColorTypeId,
 ColorTypeName,
 PartialFabricBookingMasterId ,
  --((sum(SizeQuantity)/12)*avg(FabricReqQty))/dbo.CountStripClrLengthByFabId(PrecostingId,FabricCostId) as TotalStripeCons,
   -- (((sum(SizeQuantity)/12)*avg(FabricReqQty))*percentage)/100 as TotalStripeCons,
  (((sum(SizeQuantity)/12)*avg(FabricReqQty))*percentage)/100 as TotalStripeCons,
 -- ((sum(SizeQuantity)/12)*avg(AvgGreyCons)) 
sum(SizeQuantity) as TotalFabriQty,
CountName,
CompositionName,
BodyColor,
StripColor,
avg(ProcessLoss) as ProcessLoss,
avg(FabricReqQty) as FabricReqQty,
sum(SizeQuantity) as SizeQty,
JobNo ,
BodyPartFullName,
Uom,
GmtsColor,
FabricColor,
StripeMeasurement,
BodyMeasurement,
YarnDyed,
Rate,
FabricCostId,
StripeId
  from (select    prcCst.PrecostingId,  fabCst.ColorTypeId,   pfbitemDtls.PartialFabricBookingMasterId,strpClr.StripColor,yrnCunt.Name as CountName,strpClr.BodyColor,ct.ColorTypeName,cnsmtn.ProcessLoss,compstion.CompositionName,cnsmtn.SizeQuantity,--previous columnord.JobNo ,bdyprt.BodyPartFullName,strpClr.Uom,pfbitemDtls.GmtsColor,pfbitemDtls.fabCnsColor as FabricColor,strpClr.Measurement as StripeMeasurement,strpClr.BodyMeasurement,strpClr.YarnDyed,strpClr.FabricReqQty,YrnCst.Rate ,fabCst.Id as FabricCostId,fabCst.AvgGreyCons,YrnCst.percentage,strpClr.Id as StripeId  from PartialFabricBookingItemDtlsChilds  pfbitemDtls left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostIdleft join FabricCosts fabCst on fabCst.Id=pfbitemDtls.FabricCostIdleft join   StripColors strpClr on strpClr.Id=YrnCst.StripeClrId  left join   PreCostings as prcCst on prcCst.PrecostingId= pfbitemDtls.precostingId  left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID left join Typpes as tps on tps.Id=YrnCst.TypeId left join YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id left join Compositions as compstion on YrnCst.Comp1Id=compstion.Id left join ColorTypes as ct on ct.Id=fabCst.ColorTypeId left join ConsumptionEntryForms cnsmtn on cnsmtn.Id=pfbitemDtls.fabCnsId left join BodyPartEntries as bdyprt  on fabCst.BodyPartId=bdyprt.Idwhere pfbitemDtls.PartialFabricBookingMasterId=@FabricBookingId and YrnCst.isLoadFromStripeClr=1
) 
as tbl group by 
PrecostingId,ColorTypeId,
ColorTypeName,
PartialFabricBookingMasterId ,
CountName,
CompositionName,
BodyColor,
StripColor ,
JobNo,
BodyPartFullName,
Uom,
GmtsColor,
FabricColor,
StripeMeasurement,
BodyMeasurement,
YarnDyed,
percentage,
Rate,FabricCostId,
StripeId
order by StripeId
END
 
GO
/****** Object:  StoredProcedure [dbo].[YarnInformationForFabBkngRptWithStripeColorSummary]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
    CREATE PROC [dbo].[YarnInformationForFabBkngRptWithStripeColorSummary](    @FabricBookingId int, --required parameter FabricBookingId now precostingid	@CmnCompanyId INT,	@StyleRef Varchar,	@JobNo Varchar,	@InitialOrderId int,	@Year INT,	@Month INT,	@ToDate varchar,	@FromDate varchar)ASBEGIN    select PrecostingId, PartialFabricBookingMasterId , JobNo , StripColor,  --((sum(SizeQuantity)/12)*avg(FabricReqQty))/dbo.CountStripClrLengthByFabId(PrecostingId,FabricCostId) as TotalStripeCons,    (((sum(SizeQuantity)/12)*avg(FabricReqQty))*percentage)/100 as TotalStripeCons   from (select    prcCst.PrecostingId,  fabCst.ColorTypeId,   pfbitemDtls.PartialFabricBookingMasterId,strpClr.StripColor,yrnCunt.Name as CountName,strpClr.BodyColor,ct.ColorTypeName,cnsmtn.ProcessLoss,compstion.CompositionName,cnsmtn.SizeQuantity,--previous columnord.JobNo ,bdyprt.BodyPartFullName,strpClr.Uom,pfbitemDtls.GmtsColor,pfbitemDtls.fabCnsColor as FabricColor,strpClr.Measurement as StripeMeasurement,strpClr.BodyMeasurement,strpClr.YarnDyed,strpClr.FabricReqQty,YrnCst.Rate ,fabCst.Id as FabricCostId,fabCst.AvgGreyCons,YrnCst.percentage  from PartialFabricBookingItemDtlsChilds  pfbitemDtls left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostIdleft join FabricCosts fabCst on fabCst.Id=pfbitemDtls.FabricCostIdleft join   StripColors strpClr on strpClr.Id=YrnCst.StripeClrId  left join   PreCostings as prcCst on prcCst.PrecostingId= pfbitemDtls.precostingId  left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID left join Typpes as tps on tps.Id=YrnCst.TypeId left join YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id left join Compositions as compstion on YrnCst.Comp1Id=compstion.Id left join ColorTypes as ct on ct.Id=fabCst.ColorTypeId left join ConsumptionEntryForms cnsmtn on cnsmtn.Id=pfbitemDtls.fabCnsId left join BodyPartEntries as bdyprt  on fabCst.BodyPartId=bdyprt.Idwhere pfbitemDtls.PartialFabricBookingMasterId=@FabricBookingId and YrnCst.isLoadFromStripeClr=1 --prcCst.PrecostingId=@FabricBookingId) as tbl group by PrecostingId,PartialFabricBookingMasterId ,StripColor ,JobNo,percentageEND 
GO
/****** Object:  StoredProcedure [dbo].[YarnInformationForFabricBookingRpt]    Script Date: 9/4/2023 1:58:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROC [dbo].[YarnInformationForFabricBookingRpt]
(
    @FabricBookingId int, --required parameter FabricBookingId now precostingid
	@CmnCompanyId INT,
	@StyleRef Varchar,
	@JobNo Varchar,
	@InitialOrderId int,
	@Year INT,
	@Month INT,
	@ToDate Date,
	@FromDate Date
)
AS
BEGIN
  select PrecostingId,
  ColorTypeId,
 ColorTypeName,
 PartialFabricBookingMasterId ,
  sum(TotalCons) as TotalCons ,
sum( StripeCons)  as TotalStripeCons,

CountName,
CompositionName,
BodyColor,
StripColor,
avg(ProcessLoss) as ProcessLoss

 
  from (select 
  
 prcCst.PrecostingId,
  fabCst.ColorTypeId,
 
  pfbitemDtls.PartialFabricBookingMasterId,
(case when fabCst.ColorTypeId <>9 then (dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) else 
   (dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty))   end)  as TotalCons,
 
(case when fabCst.ColorTypeId=9 then (dbo.GetStripeCstForYarnByCnsId(pfbitemDtls.fabCnsId,YrnCst.ConsQnty)) else (dbo.GetFabricConsumtionCstForYarnByFabricId(pfbitemDtls.fabCnsId)) end) as StripeCons,
strpClr.StripColor,
yrnCunt.Name as CountName,
strpClr.BodyColor,
ct.ColorTypeName,
cnsmtn.ProcessLoss,
compstion.CompositionName
  from PartialFabricBookingItemDtlsChilds  pfbitemDtls
 left join  YarnCosts as YrnCst on YrnCst.FabricCostId=pfbitemDtls.FabricCostId
left join FabricCosts fabCst on fabCst.Id=pfbitemDtls.FabricCostId
left join   StripColors strpClr on strpClr.Id=YrnCst.StripeClrId 
 left join   PreCostings as prcCst on prcCst.PrecostingId= pfbitemDtls.precostingId 
 left join  TblInitialOrders as ord  on prcCst.OrderId=ord.OrderAutoID
 left join Typpes as tps on tps.Id=YrnCst.TypeId
 left join YarnCounts as yrnCunt on YrnCst.CountId=yrnCunt.Id
 left join Compositions as compstion on YrnCst.Comp1Id=compstion.Id
 left join ColorTypes as ct on ct.Id=fabCst.ColorTypeId
 left join ConsumptionEntryForms cnsmtn on cnsmtn.Id=pfbitemDtls.fabCnsId
where 
--pfbitemDtls.PartialFabricBookingMasterId=@FabricBookingId
prcCst.PrecostingId=@FabricBookingId
) 
as tbl group by PrecostingId,ColorTypeId,ColorTypeName,PartialFabricBookingMasterId ,CountName,CompositionName,BodyColor,StripColor 
order by CountName,BodyColor,StripColor
END
 
GO
