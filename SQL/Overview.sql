-- Listagem da situação atual das solicitações por Processo. 
--[COD.PROCES;N.SOL;REQUISIT;RESPONSAVEL ATUAL;LOCALIZACAO;STATUS;DATA INICIO; DATA ULT.MOVIMENTACAO]
SELECT PW.COD_DEF_PROCES + ' - ' + DES_DEF_PROCES [Processo],
       PW.NUM_PROCES AS [N. Solicitacao],
       UPPER(FU.FULL_NAME) [Requisitante],
       UPPER(CASE
                 WHEN UPPER(FU2.FULL_NAME) IS NULL THEN 
					CASE
						WHEN CD_MATRICULA = 'System:Auto' THEN 'ROTINA AUTOMATICA PARADA'
						ELSE CD_MATRICULA
					END
                 ELSE UPPER(FU2.FULL_NAME)
             END) [Responsável],
       UPPER(NOM_ESTADO) [Localizacao],
       CASE PW.LOG_ATIV
           WHEN '1' THEN 'Aberta'
           WHEN '0' THEN 
			CASE proces.IDI_STATUS
				WHEN '4' THEN 'Cancelada'
				ELSE 'Finalizada'
            END
       END AS [Status],
       convert(CHAR,PW.START_DATE, 103) [Data Inicio],
       CASE
           WHEN PW.LOG_ATIV = 1 THEN ''
           ELSE convert(CHAR,PW.END_DATE, 103)
       END [Ultima Movimentacao]
FROM proces_workflow AS PW
LEFT JOIN
  (SELECT p.num_proces,
          max(p.num_seq_movto) num_seq_movto,
          p.IDI_STATUS,
          p.DEADLINEDATE,
          p.DEADLINEHOUR,
          p.COD_EMPRESA,
          p.NUM_SEQ_ESCOLHID,
          h.NUM_SEQ_ESTADO,
          CD_MATRICULA
   FROM TAR_PROCES p
   INNER JOIN HISTOR_PROCES h ON h.NUM_PROCES = p.NUM_PROCES
   AND h.NUM_SEQ_MOVTO = p.NUM_SEQ_MOVTO
   AND h.COD_EMPRESA = p.COD_EMPRESA
   WHERE p.NUM_SEQ_MOVTO =
       (SELECT max(pro.NUM_SEQ_MOVTO)
        FROM TAR_PROCES pro
        WHERE pro.NUM_PROCES = p.NUM_PROCES
          AND CASE idi_status
                  WHEN '4' THEN NUM_SEQ_MOVTO
                  ELSE NUM_SEQ_ESCOLHID
              END <> 0 )
     AND p.IDI_STATUS <> 3
   GROUP BY p.NUM_PROCES,
            p.IDI_STATUS,
            p.DEADLINEDATE,
            p.DEADLINEHOUR,
            p.NUM_SEQ_ESCOLHID,
            p.COD_EMPRESA,
            h.NUM_SEQ_ESTADO,
            CD_MATRICULA) proces ON PW.NUM_PROCES = proces.num_proces
AND PW.COD_EMPRESA = proces.COD_EMPRESA
LEFT JOIN FDN_USERTENANT FT ON COD_MATR_REQUISIT = FT.USER_CODE
LEFT JOIN FDN_USERTENANT FT2 ON CD_MATRICULA = FT2.USER_CODE
LEFT JOIN FDN_USER FU ON FU.USER_ID = FT.USER_ID
LEFT JOIN FDN_USER FU2 ON FU2.USER_ID = FT2.USER_ID
LEFT JOIN DEF_PROCES DP ON PW.COD_EMPRESA = DP.COD_EMPRESA
AND PW.COD_DEF_PROCES = DP.COD_DEF_PROCES
LEFT JOIN ESTADO_PROCES EP ON PW.NUM_VERS = EP.NUM_VERS
AND proces.NUM_SEQ_ESTADO = EP.NUM_SEQ
AND PW.COD_EMPRESA = EP.COD_EMPRESA
AND PW.COD_DEF_PROCES = EP.COD_DEF_PROCES

ORDER BY PW.COD_DEF_PROCES,PW.NUM_PROCES