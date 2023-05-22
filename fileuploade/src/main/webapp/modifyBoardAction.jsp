<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oreilly.servlet.MultipartRequest" %>
<%@ page import="com.oreilly.servlet.multipart.DefaultFileRenamePolicy" %>
<%@ page import="vo.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.sql.*" %>
<%
	
	//upload된 파일의 위치 
	String dir = request.getServletContext().getRealPath("/upload");
	int max = 10 * 1024 * 1024;
	MultipartRequest mRequest = new MultipartRequest(request, dir, max, "utf-8", new DefaultFileRenamePolicy());
	// System.out.println(mRequest.getOriginalFileName("baordFile") + " <-- boardFile");
	// mRequest.getOriginalFileName("baordFile") 값이 null이면 board테이블에 title만 수정
	
	// 요청값
	int boardNo = Integer.parseInt(mRequest.getParameter("boardNo"));
	int boardFileNo = Integer.parseInt(mRequest.getParameter("boardFileNo"));	
	
	// 1) board_title 수정
	String boardTitle = mRequest.getParameter("boardTitle");
	
	Class.forName("org.mariadb.jdbc.Driver");
	Connection conn = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/fileupload","root","2152");
	String boardSql = "UPDATE board SET board_title = ? WHERE board_no = ?";
	PreparedStatement boardStmt = conn.prepareStatement(boardSql);
	boardStmt.setString(1, boardTitle);
	boardStmt.setInt(2, boardNo);
	int boardRow = boardStmt.executeUpdate();
	
	// 2) 이전 boardFile 삭제, 새로운 boardFile추가 테이블을 수정
	if(mRequest.getOriginalFileName("boardFile") != null) {
		// 수정할 파일이 있으면
		// pdf 파일 유효성 검사 아니면 새로 업로드 한 파일을 삭제
		if(mRequest.getContentType("boardFile").equals("application/pdf") == false) {
			System.out.println("pdf파일이 아닙니다");
			String saveFilename = mRequest.getFilesystemName("boardFile");
			File f = new File(dir + "/" + saveFilename);
			if(f.exists()) {
				f.delete();
				System.out.println(saveFilename + "파일삭제");
			}
		} else {
			// pdf 파일이면 
			// 1) 이전 파일saveFilename) 삭제
			// 2) db 수정(update)
			String type = mRequest.getContentType("boardFile");
			String originFilename = mRequest.getOriginalFileName("boardFile");
			String saveFilename = mRequest.getFilesystemName("boardFile");
			
			BoardFile boardFile = new BoardFile();
			boardFile.setBoardFileNo(boardFileNo);
			boardFile.setType(type);
			boardFile.setOriginFileName(originFilename);
			boardFile.setSaveFileName(saveFilename);
			
			// 1) 이전파일 삭제
			String saveFilenameSql = "SELECT save_filename FROM board_file WHERE board_file_no=?";
			PreparedStatement saveFilenameStmt = conn.prepareStatement(saveFilenameSql);
			saveFilenameStmt.setInt(1, boardFile.getBoardFileNo());
			ResultSet saveFilenameRs = saveFilenameStmt.executeQuery();
			String preSaveFilename = "";
			if(saveFilenameRs.next()) {
				preSaveFilename = saveFilenameRs.getString("save_filename");
			}
			File f = new File(dir+"/"+preSaveFilename);
			if(f.exists()) {
				f.delete();
			}
			
			// 2) 수정된 파일의 정보로 db를 수정
			/*
			UPDATE board_file 
			SET origin_filename=?, save_filename=? 
			WHERE board_file_no=?
			*/
			String modifyBoardSql = "UPDATE board_file SET origin_filename=?, save_filename=? WHERE board_file_no=?";
			PreparedStatement modifyBoardStmt = conn.prepareStatement(modifyBoardSql);
			modifyBoardStmt.setString(1, boardFile.getOriginFileName());
			modifyBoardStmt.setString(2, boardFile.getSaveFileName());
			modifyBoardStmt.setInt(3, boardFile.getBoardFileNo());
			int boardFileRow = modifyBoardStmt.executeUpdate();
		}
	}
	
	
	response.sendRedirect(request.getContextPath()+"/boardList.jsp");

%>