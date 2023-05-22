<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oreilly.servlet.MultipartRequest" %>
<%@ page import="com.oreilly.servlet.multipart.DefaultFileRenamePolicy" %>
<%@ page import="vo.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.sql.*" %>
<%
	String dir = request.getServletContext().getRealPath("/upload");
	System.out.println(dir);
	
	int max = 10 * 1024 * 1024;
	// request객체를 MultipartRequest의 API를 사용할 수 있도록 랩핑
	MultipartRequest mRequest = new MultipartRequest(request, dir, max, "utf-8", new DefaultFileRenamePolicy());
	
	// MultipartRequest API를 사용하여 스트림내에서 문자갑을 반환받을 수 있다
	
	// 업로드 파일이 PDF파일이 아니면
	if(mRequest.getContentType("boardFile").equals("application/pdf") == false) {
		// 이미 저장된 파일을 삭제 
		System.out.println("PDF파일이 아닙니다");
		String saveFilename = mRequest.getFilesystemName("boardFile");
		File f = new File(dir+"/"+saveFilename); 
		if(f.exists()) {
			f.delete();
			System.out.println(dir+"/"+saveFilename+"파일삭제");
		}
		response.sendRedirect(request.getContextPath()+"/addBoard.jsp");
		return;
	}
	
	// 1) input type="text" 값반환 API
	String boardTitle = mRequest.getParameter("boardTitle");
	String memberId = mRequest.getParameter("memberId");
	
	System.out.println(boardTitle + " <-- boardTitle");
	System.out.println(memberId + " <-- memberId");
	
	Board board = new Board();
	board.setBoadTitle(boardTitle);
	board.setMemberId(memberId);
	
	// 2) input type="file" 값(파일 메타 정보)반환 API(원본파일이름, 저장된파일이름, 컨텐츠타입)
	// --> board_file 테이블에 저장
	// 파일(바이너리)은 이미 MultipartRequest 객체생성시 (request 랩핑시, 9라인) 먼저 저장
	
	String type = mRequest.getContentType("boardFile");
	String originFilename = mRequest.getOriginalFileName("boardFile");
	String saveFilename = mRequest.getFilesystemName("boardFile");
	
	System.out.println(type + " <-- type");
	System.out.println(originFilename + " <-- originFilename");
	System.out.println(saveFilename + " <-- saveFilename");

	BoardFile boardFile = new BoardFile();
	// boardFile.setBoardNo(boardNo);
	boardFile.setType(type);
	boardFile.setOriginFileName(originFilename);
	boardFile.setSaveFileName(saveFilename);
	
	Class.forName("org.mariadb.jdbc.Driver");
	Connection conn = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/fileupload","root","2152");
	
	/*
		INSERT쿼리 실행 후 기본키값 받아오기 JDBC API
		String sql = "INSERT 쿼리문";
		pstmt = con.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
		int row = pstmt.executeUpdate(); // insert 쿼리 실행
		ResultSet keyRs = pstmt.getGeneratedKeys(); // insert 후 입력된 행의 키값을 받아오는 select쿼리를 진행
		int keyValue = 0;
		if(keyRs.next()){
		keyValue = rs.getInt(1);
	*/

	/*	1) 보드 입력 쿼리 
		INSERT INTO board(board_title, member_id, createdate, updatedate)
		VALUES(?, ?, now(), now());
	*/
	String boardSql = "INSERT INTO board(board_title, member_id, createdate, updatedate) VALUES(?, ?, now(), now())";
	PreparedStatement boardStmt = conn.prepareStatement(boardSql, PreparedStatement.RETURN_GENERATED_KEYS);
	boardStmt.setString(1, boardTitle);
	boardStmt.setString(2, memberId);
	boardStmt.executeUpdate(); // board 입력 후 키값 저장 
	
	ResultSet keyRs = boardStmt.getGeneratedKeys(); // 저장된 키값을 반환
	int boardNo = 0;
	if(keyRs.next()) {
		boardNo = keyRs.getInt(1);
	}
	
	/*	2) 파일 첨부 쿼리 
		INSERT INTO board_file(boad_no, origin_filename, save_filename, path, type, createdate)
		VALUES(?, ?, ?, ?, ?, now());
	*/
	String fileSql = "INSERT INTO board_file(board_no, origin_filename, save_filename, type, path, createdate) VALUES(?, ?, ?, ?, 'upload', now())";
	PreparedStatement fileStmt = conn.prepareStatement(fileSql);
	fileStmt.setInt(1, boardNo);
	fileStmt.setString(2, originFilename);
	fileStmt.setString(3, saveFilename);
	fileStmt.setString(4, type);
	fileStmt.executeUpdate(); // board_file 입력

	response.sendRedirect(request.getContextPath()+"/boardList.jsp");

%>