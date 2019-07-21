return {
	-- example usage:
	--
	-- ['ex<T>'] = { 'ex<double>', 'ex<string>' }
	-- module = { ['ex2<K,V>'] = { 'example<char*, int>' } }
	
	qtcore = {
		['QList<T>'] = {
			'QList<int>',
			'QList<qreal>',
			'QList<QString>',
			'QList<QByteArray>',
			-- 'QList<QFileInfo>',
			'QList<QVariant>',
			'QList<QModelIndex>',
			'QList<QUrl>',
			'QList<QSize>',
			-- 'QList<QSizeF>',
		},
		['QVector<T>'] = {
			'QVector<int>',
			'QVector<qreal>',
			'QVector<QPoint>',
			'QVector<QPointF>',
			'QVector<QRect>',
			'QVector<QRectF>',
			'QVector<QLine>',
			'QVector<QLineF>',
		},
		['QFlags<Enum>'] = {
			-- 'QFlags<KeyboardModifier>',
		},
	},
	qtgui = {
		['QList<T>'] = {
			'QList<QStandardItem*>',
			-- 'QList<QRectF>',
			-- 'QList<QPolygonF>',
			'QList<QKeySequence>',
			-- 'QList<QImageTextKeyLang>',
			-- 'QList<QTableWidgetItem*>',
			-- 'QList<QAction*>',
		},
		['QVector<T>'] = {
			'QVector<QRgb>',
			'QVector<QColor>',
			'QVector<QTextLength>',
			'QVector<QGradientStop>',
			'QVector<QTextFormat>',
		},
	},
	qtwidgets = {
		['QList<T>'] = {
			'QList<QGraphicsItem*>',
			'QList<QListWidgetItem*>',
			'QList<QTableWidgetItem*>',
			'QList<QTreeWidgetItem*>',
		},
		['QVector<T>'] = {
			-- 'QVector<int>',
		},
	},
	qtnetwork = {
		['QList<T>'] = {
			-- 'QList<QSslError>',
			-- 'QList<QSslCertificate>',
			-- 'QList<QNetworkCookie>',
			-- 'QList<QSslCipher>',
			-- 'QList<QNetworkAddressEntry>',
			-- 'QList<QNetworkProxy>', 
			-- 'QList<QHostAddress>',
			-- 'QList<QUrl>',
			-- 'QList<QModelIndex>',
		}
	},
	qtsql = {
		['QList<T>'] = {
			-- 'QList<QModelIndex>',
			-- 'QList<QUrl>',
		},
		['QVector<T>'] = {
			-- 'QVector<QVariant>',
		},
	},
}
